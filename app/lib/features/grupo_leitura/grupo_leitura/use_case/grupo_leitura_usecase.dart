import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/leitura/leitura_model.dart';
import '../repository/grupo_leitura_repository.dart';

/// Abas da tela de grupos de leitura, na ordem de exibição. [rotulo] é a chave de tradução e [icone], a chave em
/// `IconsMap.mdiIcons`. Novas abas entram aqui.
enum GrupoLeituraAba {
  grupos(rotulo: 'meusGruposLeitura', icone: 'book-account-outline'),
  participantes(rotulo: 'participantes', icone: 'account-multiple-outline'),
  agenda(rotulo: 'agenda', icone: 'calendar-month-outline'),
  atividades(rotulo: 'atividades', icone: 'format-list-checks');

  const GrupoLeituraAba({required this.rotulo, required this.icone});

  final String rotulo;
  final String icone;
}

/// Regras da tela de grupos de leitura (`/v1/leitura`) e da seleção de grupo das outras abas:
/// - [meusGrupos] lista os grupos de que o usuário é dono ou participante, por nome (sem diferenciar maiúsculas) e
///   id; 404 `registroNaoEncontrado` vira lista vazia;
/// - [selecionado] escolhe o grupo das abas "Participantes", "Agenda" e "Atividades": o pedido, se ainda estiver na
///   lista, senão o primeiro;
/// - gravação ([salvar]): nome obrigatório (sem espaços nas pontas, até [kNomeMax]) e descrição opcional (até
///   [kDescricaoMax]; vazia vira nula) ([validar]). Sem `leitId` inclui (o dono é o usuário do token), com `leitId`
///   altera; só o dono altera ou exclui ([excluir]) — `somenteDonoAltera`. Sem o aceite de dados religiosos, a
///   API responde 403 `consentimentoNecessario`;
/// - sem usuário logado, `headerInvalido`.
class GrupoLeituraUseCase {
  GrupoLeituraUseCase({required this.grupoLeituraRepository, int? Function()? usuarioLogado})
    : _usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId) {
    Log.print(super.runtimeType);
  }

  final GrupoLeituraRepository grupoLeituraRepository;

  /// Id do usuário logado; injetável para testes.
  final int? Function() _usuarioLogado;

  /// Tamanhos máximos de `leit_nome` e `leit_descricao`.
  static const kNomeMax = 256;
  static const kDescricaoMax = 512;

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
  static const kSomenteDonoAltera = 'somenteDonoAltera';
  static const kGrupoObrigatorio = 'grupoLeituraObrigatorio';

  List<GrupoLeituraAba> get abas => GrupoLeituraAba.values;

  /// Usuário logado (para saber quem é o próprio participante).
  int? get usuarioLogado => _usuarioLogado();

  Future<Result<List<LeituraModel>>> meusGrupos() async {
    if (_usuarioLogado() == null) return Result.error(HandledException(message: 'headerInvalido'));

    final result = await grupoLeituraRepository.grupos();
    switch (result) {
      case Ok<List<LeituraModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<LeituraModel>>(error: final error):
        if (semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  /// Grupo selecionado: o de [leitId], se estiver em [grupos]; senão o primeiro. Nulo com a lista vazia.
  static LeituraModel? selecionado(List<LeituraModel> grupos, int? leitId) {
    for (final grupo in grupos) {
      if (grupo.leitId == leitId) return grupo;
    }
    return grupos.firstOrNull;
  }

  /// Chave de tradução do primeiro problema do [grupo] a gravar; nula se ele pode ser gravado.
  String? validar(LeituraModel grupo) {
    final nome = grupo.leitNome.trim();
    if (nome.isEmpty) return 'informeNomeGrupo';
    if (nome.length > kNomeMax) return 'nomeGrupoMuitoLongo';
    if ((grupo.leitDescricao?.trim().length ?? 0) > kDescricaoMax) return 'descricaoGrupoMuitoLonga';
    return null;
  }

  /// Inclui (sem `leitId`) ou altera o [grupo], depois de [validar]. Devolve o grupo gravado, marcado como do usuário.
  Future<Result<LeituraModel>> salvar(LeituraModel grupo) async {
    if (_usuarioLogado() == null) return Result.error(HandledException(message: 'headerInvalido'));
    if (grupo.leitId != null && !grupo.leitDono) return Result.error(HandledException(message: kSomenteDonoAltera));
    final erro = validar(grupo);
    if (erro != null) return Result.error(HandledException(message: erro));

    final descricao = grupo.leitDescricao?.trim();
    final registro = LeituraModel(
      leitId: grupo.leitId,
      leitNome: grupo.leitNome.trim(),
      leitDescricao: (descricao?.isEmpty ?? true) ? null : descricao,
    );
    final result = registro.leitId == null
        ? await grupoLeituraRepository.incluir(registro)
        : await grupoLeituraRepository.alterar(registro);
    return switch (result) {
      Ok<LeituraModel>(value: final gravado) => Result.ok(gravado.comDono(true)),
      Error<LeituraModel>(error: final error) => Result.error(error),
    };
  }

  /// Exclui o grupo (com agenda, atividades e participantes); só o dono.
  Future<Result<void>> excluir(LeituraModel grupo) async {
    final leitId = grupo.leitId;
    if (leitId == null) return Result.error(HandledException(message: kRegistroNaoEncontrado));
    if (!grupo.leitDono) return Result.error(HandledException(message: kSomenteDonoAltera));
    return grupoLeituraRepository.excluir(leitId);
  }

  static List<LeituraModel> ordenar(Iterable<LeituraModel> grupos) => List.unmodifiable(
    grupos.toList()..sort((a, b) {
      final nome = a.leitNome.trim().toLowerCase().compareTo(b.leitNome.trim().toLowerCase());
      return nome != 0 ? nome : (a.leitId ?? 0).compareTo(b.leitId ?? 0);
    }),
  );

  /// Papel do usuário no grupo (chave de tradução): dono ou participante.
  static String papel(LeituraModel grupo) => grupo.leitDono ? 'donoDoGrupo' : 'participanteDoGrupo';

  /// Chave de tradução da mensagem de um erro.
  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static bool semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);
}
