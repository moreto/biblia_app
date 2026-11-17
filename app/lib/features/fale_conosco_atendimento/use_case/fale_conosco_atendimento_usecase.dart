import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/configuracao/configuracao_model.dart';
import '../../../data/model/fale_conosco/fale_conosco_atendimento_model.dart';
import '../../fale_conosco/use_case/fale_conosco_usecase.dart';
import '../repository/fale_conosco_atendimento_repository.dart';

/// Opções das configurações do Fale Conosco usadas no atendimento.
class FaleConoscoAtendimentoOpcoes {
  const FaleConoscoAtendimentoOpcoes({
    this.categorias = const [],
    this.prioridades = const [],
    this.situacoes = const [],
    this.origens = const [],
  });

  final List<FaleConoscoOpcao> categorias;
  final List<FaleConoscoOpcao> prioridades;
  final List<FaleConoscoOpcao> situacoes;
  final List<FaleConoscoOpcao> origens;
}

/// Chamado aberto no atendimento, com todas as interações (inclusive as internas).
class FaleConoscoAtendimentoDetalhe {
  const FaleConoscoAtendimentoDetalhe({required this.chamado, this.interacoes = const []});

  final FaleConoscoAtendimentoModel chamado;
  final List<FaleConoscoAtendimentoInteracaoModel> interacoes;
}

/// Filtro da fila na tela: situação (`cite_chave` de `faleConoscoStatus`) e "só os meus".
typedef FaleConoscoAtendimentoFiltro = ({int? situacao, bool meus});

/// Resposta do atendente: texto, nota interna (não vista pelo solicitante) e nova situação (nula mantém).
typedef FaleConoscoAtendimentoResposta = ({String texto, bool interna, int? situacao});

/// Classificação do chamado.
typedef FaleConoscoAtendimentoClassificacao = ({int categoria, int prioridade, int situacao});

/// Regras da tela "Atendimento do Fale conosco" (o app não restringe o acesso; se a API recusar, responde 403
/// `acessoNegado`):
/// - [opcoes] traz categorias, prioridades, situações e origens das configurações (achadas como na tela do
///   solicitante, [FaleConoscoUseCase.configuracao]); [fila] traz os chamados do [filtro] (situação e, em "meus", o
///   usuário logado como responsável), na ordem da API (prioridade maior primeiro, depois os mais antigos);
/// - [detalhe] traz o chamado completo e todas as interações, em paralelo;
/// - [responder] grava a resposta (ou nota interna, se [FaleConoscoAtendimentoResposta.interna]) com a nova situação
///   opcional e recarrega o detalhe. A API marca a primeira resposta (não interna) e torna o atendente responsável
///   se o chamado não tiver;
/// - [classificar], [assumir], [liberar], [fechar] e [reabrir] gravam no `PUT`, que exige o chamado inteiro: os
///   campos que não mudam vão com o valor atual. Fechar também passa a situação para `fechado` e reabrir para
///   `emAtendimento` (quando essas opções existem na configuração);
/// - [excluir] faz a exclusão lógica;
/// - textos: [rotulo], [data], [duracao] do tempo de resposta e [nivelPrioridade] (posição da prioridade, para a cor).
class FaleConoscoAtendimentoUseCase {
  FaleConoscoAtendimentoUseCase({required this.faleConoscoAtendimentoRepository, int? Function()? usuarioId})
    : _usuarioId = usuarioId ?? (() => null) {
    Log.print(super.runtimeType);
  }

  final FaleConoscoAtendimentoRepository faleConoscoAtendimentoRepository;
  final int? Function() _usuarioId;

  static const kConfigPrioridade = (codigo: 'faleConoscoPrioridade', nome: 'Fale Conosco - Prioridade');

  /// `cite_valor` das situações usadas ao fechar e reabrir.
  static const kSituacaoFechado = 'fechado';
  static const kSituacaoEmAtendimento = 'emAtendimento';

  static const textoMaximo = FaleConoscoUseCase.textoMaximo;

  /// Mensagens (chaves de tradução) de sucesso.
  static const kRespondido = 'respostaEnviada';
  static const kNotaGravada = 'notaInternaGravada';
  static const kAtualizado = 'chamadoAtualizado';
  static const kExcluido = 'chamadoExcluido';

  /// Usuário logado (o atendente).
  int? get usuarioId => _usuarioId();

  Future<Result<FaleConoscoAtendimentoOpcoes>> opcoes() async {
    final configuracoes = await faleConoscoAtendimentoRepository.configuracoes();
    final List<ConfiguracaoModel> lista;
    switch (configuracoes) {
      case Ok(value: final value):
        lista = value;
      case Error(error: final error):
        return Result.error(error);
    }

    final (categorias, prioridades, situacoes, origens) = await (
      _itens(lista, FaleConoscoUseCase.kConfigCategoria),
      _itens(lista, kConfigPrioridade),
      _itens(lista, FaleConoscoUseCase.kConfigStatus),
      _itens(lista, FaleConoscoUseCase.kConfigOrigem),
    ).wait;
    for (final r in [categorias, prioridades, situacoes, origens]) {
      if (r case Error(error: final error)) return Result.error(error);
    }
    List<FaleConoscoOpcao> valor(Result<List<FaleConoscoOpcao>> r) => (r as Ok<List<FaleConoscoOpcao>>).value;
    return Result.ok(
      FaleConoscoAtendimentoOpcoes(
        categorias: valor(categorias),
        prioridades: valor(prioridades),
        situacoes: valor(situacoes),
        origens: valor(origens),
      ),
    );
  }

  Future<Result<List<FaleConoscoOpcao>>> _itens(
    List<ConfiguracaoModel> configuracoes,
    ({String codigo, String nome}) config,
  ) async {
    final confId = FaleConoscoUseCase.configuracao(configuracoes, codigo: config.codigo, nome: config.nome)?.confId;
    if (confId == null) return const Result.ok([]);
    final result = await faleConoscoAtendimentoRepository.itens(confId);
    return switch (result) {
      Ok(value: final itens) => Result.ok(FaleConoscoUseCase.opcoes(itens)),
      Error(error: final error) => _semRegistros(error) ? const Result.ok([]) : Result.error(error),
    };
  }

  /// Filtro da API a partir do filtro da tela; "meus" sem usuário logado não filtra por responsável.
  FaleConoscoAtendimentoFiltroModel filtroApi(FaleConoscoAtendimentoFiltro filtro) =>
      FaleConoscoAtendimentoFiltroModel(fconStatus: filtro.situacao, fconResponsavelId: filtro.meus ? usuarioId : null);

  Future<Result<List<FaleConoscoAtendimentoModel>>> fila(FaleConoscoAtendimentoFiltro filtro) async {
    final result = await faleConoscoAtendimentoRepository.fila(filtroApi(filtro));
    if (result case Error(error: final error) when _semRegistros(error)) return const Result.ok([]);
    return result;
  }

  Future<Result<FaleConoscoAtendimentoDetalhe>> detalhe(int fconId) async {
    final (chamado, interacoes) = await (
      faleConoscoAtendimentoRepository.chamado(fconId),
      faleConoscoAtendimentoRepository.interacoes(fconId),
    ).wait;
    switch ((chamado, interacoes)) {
      case (Ok(value: final chamado), Ok(value: final interacoes)):
        return Result.ok(
          FaleConoscoAtendimentoDetalhe(
            chamado: chamado,
            interacoes: [...interacoes]..sort((a, b) => a.fcinId.compareTo(b.fcinId)),
          ),
        );
      case (Error(error: final error), _) || (_, Error(error: final error)):
        return Result.error(error);
    }
  }

  /// Problema da resposta (chave de tradução); nulo se pode gravar.
  static String? validarResposta(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return 'informeMensagem';
    if (t.length > textoMaximo) return 'mensagemMuitoLonga';
    return null;
  }

  /// Grava a resposta (ou nota interna) e devolve o detalhe recarregado.
  Future<Result<FaleConoscoAtendimentoDetalhe>> responder(
    FaleConoscoAtendimentoModel chamado,
    FaleConoscoAtendimentoResposta resposta,
  ) async {
    final erro = validarResposta(resposta.texto);
    if (erro != null) return Result.error(HandledException(message: erro));
    final result = await faleConoscoAtendimentoRepository.responder(
      FaleConoscoAtendimentoInteracaoBodyModel(
        fconId: chamado.fconId,
        fcinTexto: resposta.texto.trim(),
        fcinInterna: resposta.interna,
        fconStatus: resposta.situacao == chamado.fconStatus ? null : resposta.situacao,
      ),
    );
    if (result case Error(error: final error)) return Result.error(error);
    return detalhe(chamado.fconId);
  }

  Future<Result<FaleConoscoAtendimentoModel>> classificar(
    FaleConoscoAtendimentoModel chamado,
    FaleConoscoAtendimentoClassificacao c,
  ) => _atualizar(chamado, categoria: c.categoria, prioridade: c.prioridade, situacao: c.situacao);

  /// Torna o usuário logado responsável pelo chamado.
  Future<Result<FaleConoscoAtendimentoModel>> assumir(FaleConoscoAtendimentoModel chamado) async {
    final id = usuarioId;
    if (id == null) return Result.error(HandledException(message: 'headerInvalido'));
    return _atualizar(chamado, responsavel: (id,));
  }

  /// Deixa o chamado sem responsável.
  Future<Result<FaleConoscoAtendimentoModel>> liberar(FaleConoscoAtendimentoModel chamado) =>
      _atualizar(chamado, responsavel: (null,));

  /// Fecha o chamado e passa a situação para `fechado` (se existir na configuração).
  Future<Result<FaleConoscoAtendimentoModel>> fechar(
    FaleConoscoAtendimentoModel chamado,
    FaleConoscoAtendimentoOpcoes opcoes,
  ) => _atualizar(chamado, fechado: true, situacao: _situacao(opcoes, kSituacaoFechado));

  /// Reabre o chamado e passa a situação para `emAtendimento` (se existir na configuração).
  Future<Result<FaleConoscoAtendimentoModel>> reabrir(
    FaleConoscoAtendimentoModel chamado,
    FaleConoscoAtendimentoOpcoes opcoes,
  ) => _atualizar(chamado, fechado: false, situacao: _situacao(opcoes, kSituacaoEmAtendimento));

  Future<Result<void>> excluir(FaleConoscoAtendimentoModel chamado) =>
      faleConoscoAtendimentoRepository.excluir(chamado.fconId);

  /// `PUT` com o chamado inteiro; [responsavel] é um record para distinguir "não mudar" (nulo) de "sem responsável"
  /// (`(null,)`).
  Future<Result<FaleConoscoAtendimentoModel>> _atualizar(
    FaleConoscoAtendimentoModel chamado, {
    int? categoria,
    int? prioridade,
    int? situacao,
    (int?,)? responsavel,
    bool? fechado,
  }) => faleConoscoAtendimentoRepository.atualizar(
    FaleConoscoAtendimentoBodyModel(
      fconId: chamado.fconId,
      fconCategoria: categoria ?? chamado.fconCategoria,
      fconPrioridade: prioridade ?? chamado.fconPrioridade,
      fconStatus: situacao ?? chamado.fconStatus,
      fconResponsavelId: responsavel == null ? chamado.fconResponsavelId : responsavel.$1,
      fconFechado: fechado,
    ),
  );

  static int? _situacao(FaleConoscoAtendimentoOpcoes opcoes, String rotulo) =>
      opcoes.situacoes.where((s) => s.rotulo == rotulo).firstOrNull?.chave;

  /// Rótulo (chave de tradução) do código nas [opcoes]; `?` se não estiver na configuração.
  static String rotulo(List<FaleConoscoOpcao> opcoes, int? chave) => FaleConoscoUseCase.rotulo(opcoes, chave);

  /// Posição da prioridade de 0 (menor) a 1 (maior) na ordem da configuração; nula se não estiver nela.
  static double? nivelPrioridade(List<FaleConoscoOpcao> prioridades, int chave) {
    final i = prioridades.indexWhere((p) => p.chave == chave);
    if (i < 0) return null;
    return prioridades.length == 1 ? 1 : i / (prioridades.length - 1);
  }

  /// Data e hora como "dd/MM/yyyy HH:mm"; nula sem data.
  static String? data(DateTime? quando) => FaleConoscoUseCase.data(quando);

  /// Tempo como "2d 3h", "4h 15min", "12min" ou "<1min"; nulo sem valor.
  static String? duracao(int? segundos) {
    if (segundos == null || segundos < 0) return null;
    final d = Duration(seconds: segundos);
    if (d.inMinutes < 1) return '<1min';
    if (d.inHours < 1) return '${d.inMinutes}min';
    if (d.inDays < 1) return '${d.inHours}h ${d.inMinutes % 60}min';
    return '${d.inDays}d ${d.inHours % 24}h';
  }

  static String mensagemErro(Exception error) => FaleConoscoUseCase.mensagemErro(error);

  static bool _semRegistros(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
