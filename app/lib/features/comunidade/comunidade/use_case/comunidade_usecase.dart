import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_denominacao_model.dart';
import '../../../../data/model/comunidade/comunidade_model.dart';
import '../../../../data/model/comunidade/comunidade_tipo_model.dart';
import '../repository/comunidade_repository.dart';

/// Abas da tela de comunidades, na ordem de exibição. [rotulo] é a chave de tradução e [icone], a chave em
/// `IconsMap.mdiIcons`. Novas abas entram aqui e em [ComunidadeUseCase.abas].
enum ComunidadeAba {
  minhas(rotulo: 'minhasComunidades', icone: 'account-group-outline'),
  enderecos(rotulo: 'enderecos', icone: 'map-marker-outline'),
  contatos(rotulo: 'contatos', icone: 'card-account-phone-outline');

  const ComunidadeAba({required this.rotulo, required this.icone});

  final String rotulo;
  final String icone;
}

/// Comunidade pronta para exibição, com os nomes do tipo e da denominação e o ícone do tipo (`ctip_icone`, chave de
/// `IconsMap.mdiIcons`) — nulos se não informados ou não encontrados.
typedef ComunidadeResumo = ({ComunidadeModel comunidade, String? tipo, String? denominacao, String? icone});

/// Conteúdo da aba "Minhas comunidades": a lista e as opções de tipo e denominação do formulário.
typedef MinhasComunidades = ({
  List<ComunidadeResumo> comunidades,
  List<ComunidadeTipoModel> tipos,
  List<ComunidadeDenominacaoModel> denominacoes,
});

/// Regras da tela de comunidades:
/// - abas disponíveis em [abas];
/// - "Minhas comunidades" lista as comunidades cadastradas pelo usuário logado, por nome (sem diferenciar
///   maiúsculas) e id, com os nomes do tipo e da denominação; tipos e denominações também são as opções do
///   formulário;
/// - falha ao carregar tipos ou denominações não impede a lista: os nomes ficam de fora e as opções vazias;
/// - 404 `registroNaoEncontrado` na lista vira lista vazia (`nenhumaComunidadeCadastrada` na tela);
/// - gravação ([salvar]): nome obrigatório (sem espaços nas pontas, até [kNomeMax]), tipo e denominação
///   obrigatórios ([validar]); sem `comuId` inclui, com `comuId` altera. A API grava o usuário do token;
/// - exclusão ([excluir]) pelo `comuId`;
/// - sem usuário logado, `headerInvalido`.
class ComunidadeUseCase {
  ComunidadeUseCase({required this.comunidadeRepository, int? Function()? usuarioLogado})
    : _usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId) {
    Log.print(super.runtimeType);
  }

  final ComunidadeRepository comunidadeRepository;

  /// Id do usuário logado; injetável para testes.
  final int? Function() _usuarioLogado;

  /// Tamanho máximo do nome da comunidade.
  static const kNomeMax = 100;

  List<ComunidadeAba> get abas => ComunidadeAba.values;

  Future<Result<MinhasComunidades>> minhasComunidades() async {
    final usuaId = _usuarioLogado();
    if (usuaId == null) {
      return Result.error(HandledException(message: 'headerInvalido'));
    }

    final (comunidades, tiposResult, denominacoesResult) = await (
      comunidadeRepository.comunidadesDoUsuario(usuaId),
      comunidadeRepository.tipos(),
      comunidadeRepository.denominacoes(),
    ).wait;

    final tipos = switch (tiposResult) {
      Ok<List<ComunidadeTipoModel>>(value: final value) => value,
      Error<List<ComunidadeTipoModel>>() => const <ComunidadeTipoModel>[],
    };
    final denominacoes = switch (denominacoesResult) {
      Ok<List<ComunidadeDenominacaoModel>>(value: final value) => value,
      Error<List<ComunidadeDenominacaoModel>>() => const <ComunidadeDenominacaoModel>[],
    };

    final List<ComunidadeModel> lista;
    switch (comunidades) {
      case Ok<List<ComunidadeModel>>(value: final value):
        lista = value;
      case Error<List<ComunidadeModel>>(error: final error):
        if (!_semRegistros(error)) return Result.error(error);
        lista = const [];
    }

    final nomesTipo = {for (final t in tipos) t.ctipId: t.ctipNome};
    final iconesTipo = {for (final t in tipos) t.ctipId: t.ctipIcone};
    final nomesDenominacao = {for (final d in denominacoes) d.cdenId: d.cdenNome};

    return Result.ok((
      comunidades: ordenar([
        for (final comunidade in lista)
          (
            comunidade: comunidade,
            tipo: _nome(nomesTipo[comunidade.ctipId]),
            denominacao: _nome(nomesDenominacao[comunidade.cdenId]),
            icone: _nome(iconesTipo[comunidade.ctipId]),
          ),
      ]),
      tipos: tipos,
      denominacoes: denominacoes,
    ));
  }

  /// Chave de tradução do primeiro problema da [comunidade] a gravar; nula se ela pode ser gravada.
  String? validar(ComunidadeModel comunidade) {
    final nome = comunidade.comuNome.trim();
    if (nome.isEmpty) return 'nomeObrigatorio';
    if (nome.length > kNomeMax) return 'nomeComunidadeMuitoLongo';
    if ((comunidade.ctipId ?? 0) < 1) return 'tipoObrigatorio';
    if ((comunidade.cdenId ?? 0) < 1) return 'denominacaoObrigatoria';
    return null;
  }

  /// Inclui (sem `comuId`) ou altera a [comunidade], depois de [validar]; o nome é gravado sem espaços nas pontas.
  Future<Result<ComunidadeModel>> salvar(ComunidadeModel comunidade) async {
    if (_usuarioLogado() == null) {
      return Result.error(HandledException(message: 'headerInvalido'));
    }
    final erro = validar(comunidade);
    if (erro != null) return Result.error(HandledException(message: erro));

    final registro = ComunidadeModel(
      comuId: comunidade.comuId,
      comuNome: comunidade.comuNome.trim(),
      ctipId: comunidade.ctipId,
      cdenId: comunidade.cdenId,
    );
    return registro.comuId == null ? comunidadeRepository.incluir(registro) : comunidadeRepository.alterar(registro);
  }

  Future<Result<void>> excluir(ComunidadeModel comunidade) async {
    final comuId = comunidade.comuId;
    if (comuId == null) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    return comunidadeRepository.excluir(comuId);
  }

  static List<ComunidadeResumo> ordenar(Iterable<ComunidadeResumo> comunidades) {
    final lista = comunidades.toList();
    lista.sort((a, b) {
      final nome = a.comunidade.comuNome.trim().toLowerCase().compareTo(b.comunidade.comuNome.trim().toLowerCase());
      return nome != 0 ? nome : (a.comunidade.comuId ?? 0).compareTo(b.comunidade.comuId ?? 0);
    });
    return List.unmodifiable(lista);
  }

  /// Linha de detalhe do card: "Tipo · Denominação", só com o que houver; nula se nenhum dos dois.
  static String? descricao(ComunidadeResumo resumo) {
    final partes = [resumo.tipo, resumo.denominacao].whereType<String>();
    return partes.isEmpty ? null : partes.join(' · ');
  }

  static String? _nome(String? nome) {
    final texto = nome?.trim();
    return (texto?.isEmpty ?? true) ? null : texto;
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
