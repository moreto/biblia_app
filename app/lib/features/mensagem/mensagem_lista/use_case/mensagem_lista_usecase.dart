import 'package:commons/commons.dart';
import 'package:intl/intl.dart';
import 'package:service/service.dart';

import '../../../../data/model/mensagem/mensagem_recebida_model.dart';
import '../repository/mensagem_lista_repository.dart';

/// Filtros da caixa de mensagens: rótulo (chave de tradução) e ícone (em `IconsMap.mdiIcons`).
enum MensagemFiltro {
  /// Não arquivadas (lidas e não lidas).
  entrada(rotulo: 'caixaEntrada', icone: 'inbox-outline'),

  /// Não lidas e não arquivadas.
  naoLidas(rotulo: 'naoLidas', icone: 'email-outline'),

  /// Arquivadas.
  arquivadas(rotulo: 'arquivadas', icone: 'archive-outline');

  const MensagemFiltro({required this.rotulo, required this.icone});

  final String rotulo;
  final String icone;
}

/// Regras da tela "Mensagens" (mensagens que o usuário recebeu):
/// - a lista vem de `/v1/mensagem-usuario/recebidas`, das mais recentes para as mais antigas (sem data por último);
///   404 `registroNaoEncontrado` vira lista vazia;
/// - [filtrar] separa entrada (não arquivadas), não lidas (não arquivadas) e arquivadas; [naoLidas] conta as não
///   lidas da entrada;
/// - abrir uma mensagem não lida a marca como lida ([abrir]); dá para voltar a não lida ([marcarLida]) e
///   arquivar/desarquivar ([arquivar]); a situação é gravada em `PUT /v1/mensagem-usuario` e aplicada à mensagem;
/// - remetente: mensagens de sistema não têm remetente ([remetente] nulo; a tela mostra "Sistema"); as outras
///   mostram "Nome (@usuario)", só o nome ou só "@usuario";
/// - datas como "dd/MM/yyyy HH:mm" ([data]); [resumo] é o texto numa linha só, para o card.
class MensagemListaUseCase {
  MensagemListaUseCase({required this.mensagemListaRepository}) {
    Log.print(super.runtimeType);
  }

  final MensagemListaRepository mensagemListaRepository;

  Future<Result<List<MensagemRecebidaModel>>> recebidas() async {
    final result = await mensagemListaRepository.recebidas();
    switch (result) {
      case Ok<List<MensagemRecebidaModel>>(value: final lista):
        return Result.ok(ordenar(lista));
      case Error<List<MensagemRecebidaModel>>(error: final error):
        if (_semRegistros(error)) return const Result.ok([]);
        return result;
    }
  }

  /// Mais recentes primeiro; sem data por último.
  static List<MensagemRecebidaModel> ordenar(List<MensagemRecebidaModel> lista) => [...lista]
    ..sort((a, b) {
      final da = a.recebidaEm;
      final db = b.recebidaEm;
      if (da == null || db == null) return da == null ? (db == null ? 0 : 1) : -1;
      return db.compareTo(da);
    });

  static List<MensagemRecebidaModel> filtrar(List<MensagemRecebidaModel> lista, MensagemFiltro filtro) => [
    for (final m in lista)
      if (switch (filtro) {
        MensagemFiltro.entrada => !m.musuArquivada,
        MensagemFiltro.naoLidas => !m.musuArquivada && !m.musuLida,
        MensagemFiltro.arquivadas => m.musuArquivada,
      })
        m,
  ];

  /// Não lidas da entrada (não arquivadas).
  static int naoLidas(List<MensagemRecebidaModel> lista) => filtrar(lista, MensagemFiltro.naoLidas).length;

  /// Ao abrir: marca como lida se ainda não estiver; já lida, devolve a própria mensagem sem chamar a API.
  Future<Result<MensagemRecebidaModel>> abrir(MensagemRecebidaModel mensagem) async =>
      mensagem.musuLida ? Result.ok(mensagem) : marcarLida(mensagem, true);

  Future<Result<MensagemRecebidaModel>> marcarLida(MensagemRecebidaModel mensagem, bool lida) =>
      _atualizar(mensagem, lida: lida);

  Future<Result<MensagemRecebidaModel>> arquivar(MensagemRecebidaModel mensagem, bool arquivada) =>
      _atualizar(mensagem, arquivada: arquivada);

  Future<Result<MensagemRecebidaModel>> _atualizar(
    MensagemRecebidaModel mensagem, {
    bool? lida,
    bool? arquivada,
  }) async {
    final result = await mensagemListaRepository.atualizar(musuId: mensagem.musuId, lida: lida, arquivada: arquivada);
    switch (result) {
      case Ok<Map<String, dynamic>>(value: final situacao):
        try {
          return Result.ok(mensagem.comSituacao(situacao));
        } on FormatException {
          return Result.error(HandledException(message: 'formatoMensagemInvalido'));
        }
      case Error<Map<String, dynamic>>(error: final error):
        return Result.error(error);
    }
  }

  /// "Nome (@usuario)", só o nome ou só "@usuario"; nulo em mensagem de sistema ou sem remetente.
  static String? remetente(MensagemRecebidaModel mensagem) {
    if (mensagem.sistema) return null;
    final nome = _texto(mensagem.remetenteNome);
    final usuario = _texto(mensagem.remetenteUsuario);
    if (nome != null && usuario != null) return '$nome (@$usuario)';
    return nome ?? (usuario == null ? null : '@$usuario');
  }

  /// Texto em uma linha (quebras e espaços repetidos viram um espaço), para o card.
  static String resumo(MensagemRecebidaModel mensagem) => mensagem.mensTexto.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? data(DateTime? quando) => quando == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(quando);

  /// Resposta do usuário à mensagem; nula se não respondeu.
  static String? resposta(MensagemRecebidaModel mensagem) =>
      mensagem.musuRespondida ? _texto(mensagem.musuResposta) : null;

  static String mensagemErro(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  static String? _texto(String? valor) {
    final texto = valor?.trim();
    return (texto?.isEmpty ?? true) ? null : texto;
  }

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
