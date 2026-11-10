import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../../../../data/model/biblia/versiculo_indicacao_usuario_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../../../dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import '../use_case/biblia_leitura_usecase.dart';
import '../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import '../versiculo_indicacao/use_case/versiculo_indicacao_usuario_usecase.dart';

/// Estado da leitura da Bíblia.
///
/// Ao ser criado executa [carregarCommand]: versões, testamentos e livros e, para a versão escolhida (a primeira),
/// o índice de capítulos e o progresso de leitura do usuário. A partir daí:
/// - [versaoCommand] troca a versão e recarrega índice, progresso e o capítulo aberto;
/// - [selecionarTestamento] filtra os livros do índice (nulo = todos);
/// - [abrirCapituloCommand] carrega os versículos de um capítulo e as reações do usuário a eles;
///   [fecharCapitulo] volta ao índice;
/// - [marcarLidoCommand] marca o capítulo aberto como lido (ou desmarca, se já estava completo);
/// - [marcarVersiculoCommand] marca um versículo como lido (ou desmarca), mantendo o comentário da reação;
/// - [destacarVersiculo] marca (ou desmarca) a linha tocada como indicativo de onde o usuário está lendo; é só
///   visual, não grava nada, e some ao trocar de capítulo;
/// - [estadoIndicacao] diz se o usuário indicou o versículo e se comentou, pelas indicações dele no capítulo
///   (carregadas ao abrir o capítulo e atualizadas ao indicar ou remover);
/// - depois de marcar ou desmarcar (capítulo ou versículo), [feedback] guarda a chave da mensagem de confirmação,
///   lida uma única vez pela view com [consumirFeedback];
/// - [indicacoesCommand], [indicarCommand] e [removerIndicacaoCommand] tratam a indicação do versículo selecionado;
/// - [indicados] são os usuários que recebem a indicação do usuário, carregados com ela; [buscarUsuarios] procura
///   destinatários, [adicionarIndicadoCommand] inclui e [removerIndicadoCommand] remove.
class BibliaLeituraViewmodel extends ChangeNotifier {
  BibliaLeituraViewmodel({
    required this.bibliaLeituraUseCase,
    required this.versiculoIndicacaoUseCase,
    required this.versiculoReacaoUseCase,
    required this.versiculoIndicacaoUsuarioUseCase,
  }) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final VersiculoReacaoUseCase versiculoReacaoUseCase;
  final VersiculoIndicacaoUsuarioUseCase versiculoIndicacaoUsuarioUseCase;

  late final Command1<VersiculoReacaoModel, VersiculoTextoModel> marcarVersiculoCommand = Command1(_marcarVersiculo);

  /// Reações do usuário aos versículos do capítulo aberto, por `versId`.
  Map<int, VersiculoReacaoModel> _reacoes = const {};

  /// O versículo está marcado como lido pelo usuário.
  bool versiculoLido(int versId) => _reacoes[versId]?.vreaLido ?? false;

  /// Indicações do usuário aos versículos do capítulo aberto, por `versId`.
  Map<int, VersiculoIndicacaoModel> _indicacoesCapitulo = const {};

  /// Estado da indicação do usuário ao versículo (não indicado, indicado ou com comentário).
  EstadoIndicacao estadoIndicacao(int versId) => versiculoIndicacaoUseCase.estado(_indicacoesCapitulo[versId]);

  int? _versiculoDestacado;

  /// Versículo tocado como indicativo de leitura; nulo quando nenhum.
  int? get versiculoDestacado => _versiculoDestacado;

  /// Destaca a linha do versículo [versId] como indicativo de leitura; tocar de novo remove o destaque.
  void destacarVersiculo(int versId) {
    _versiculoDestacado = _versiculoDestacado == versId ? null : versId;
    notifyListeners();
  }

  /// Versículo cuja marcação está sendo gravada; nulo quando nenhum.
  int? _versiculoGravando;
  int? get versiculoGravando => _versiculoGravando;

  /// Confirmação da última marcação (capítulo ou versículo); nula se não há mensagem pendente.
  FeedbackLeitura? _feedback;
  FeedbackLeitura? get feedback => _feedback;

  /// Devolve a confirmação pendente de [feedback] e a limpa, para ser mostrada uma única vez.
  FeedbackLeitura? consumirFeedback() {
    final mensagem = _feedback;
    _feedback = null;
    return mensagem;
  }

  final BibliaLeituraUseCase bibliaLeituraUseCase;
  final VersiculoIndicacaoUseCase versiculoIndicacaoUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, VersaoModel> versaoCommand = Command1(_trocarVersao);
  late final Command1<List<VersiculoTextoModel>, CapituloRef> abrirCapituloCommand = Command1(_abrirCapitulo);
  late final Command0<CapituloLidoModel?> marcarLidoCommand = Command0(_marcarLido);
  late final Command1<IndicacoesVersiculo, VersiculoTextoModel> indicacoesCommand = Command1(_carregarIndicacoes);

  /// Argumento: comentário opcional da indicação.
  late final Command1<VersiculoIndicacaoModel, String?> indicarCommand = Command1(_indicar);
  late final Command0<void> removerIndicacaoCommand = Command0(_removerIndicacao);
  late final Command1<VersiculoIndicacaoUsuarioModel, UsuarioResumoModel> adicionarIndicadoCommand = Command1(
    _adicionarIndicado,
  );
  late final Command1<void, VersiculoIndicacaoUsuarioModel> removerIndicadoCommand = Command1(_removerIndicado);

  List<VersiculoIndicacaoUsuarioModel> _indicados = const [];

  /// Usuários que recebem a indicação do usuário ao [versiculoSelecionado].
  List<VersiculoIndicacaoUsuarioModel> get indicados => _indicados;

  List<UsuarioResumoModel> _usuariosEncontrados = const [];

  /// Resultado da última [buscarUsuarios], sem quem já está em [indicados].
  List<UsuarioResumoModel> get usuariosEncontrados => _usuariosEncontrados;

  bool _buscandoUsuarios = false;
  bool get buscandoUsuarios => _buscandoUsuarios;

  /// Chave de tradução do erro da última busca de usuários; nula se não houve erro.
  String? _erroBuscaUsuarios;
  String? get erroBuscaUsuarios => _erroBuscaUsuarios;

  /// Numera as buscas para descartar respostas de buscas antigas (o usuário continua digitando).
  int _buscaSequencia = 0;

  /// Nome mostrado de um usuário (nome completo ou, sem ele, nome de usuário).
  String? nomeUsuario({String? udetNome, String? udetUsuario}) =>
      versiculoIndicacaoUsuarioUseCase.nomeExibicao(udetNome: udetNome, udetUsuario: udetUsuario);

  /// Tamanho mínimo do texto para buscar usuários.
  int get buscaUsuarioMinimo => VersiculoIndicacaoUsuarioUseCase.buscaMinimo;

  List<VersaoModel> _versoes = const [];
  List<VersaoModel> get versoes => _versoes;

  VersaoModel? _versao;
  VersaoModel? get versao => _versao;

  List<TestamentoModel> _testamentos = const [];
  List<TestamentoModel> get testamentos => _testamentos;

  int? _testamentoId;

  /// Testamento do filtro; nulo mostra todos os livros.
  int? get testamentoId => _testamentoId;

  List<LivroModel> _livros = const [];

  /// Capítulos da versão por livro; nulo até o primeiro carregamento concluir (ou se ele falhar).
  Map<int, List<IndiceCapituloModel>>? _indice;
  Map<int, List<IndiceCapituloModel>>? get indice => _indice;

  Map<String, CapituloLidoModel> _lidos = const {};

  CapituloRef? _capitulo;

  /// Capítulo aberto para leitura; nulo mostra o índice.
  CapituloRef? get capitulo => _capitulo;

  List<VersiculoTextoModel>? _versiculos;

  /// Versículos do [capitulo]; nulo enquanto carrega ou se o carregamento falhou.
  List<VersiculoTextoModel>? get versiculos => _versiculos;

  VersiculoTextoModel? _versiculoSelecionado;
  VersiculoTextoModel? get versiculoSelecionado => _versiculoSelecionado;

  IndicacoesVersiculo? _indicacoes;

  /// Indicações do [versiculoSelecionado]; nulas enquanto carregam ou se a consulta falhou.
  IndicacoesVersiculo? get indicacoes => _indicacoes;

  /// Livros do índice da versão, filtrados pelo [testamentoId], na ordem da Bíblia.
  List<LivroModel> get livros {
    final indice = _indice ?? const {};
    return _livros
        .where((livro) => indice.containsKey(livro.livrId))
        .where((livro) => _testamentoId == null || livro.testId == _testamentoId)
        .toList(growable: false);
  }

  List<IndiceCapituloModel> capitulosDo(int livrId) => _indice?[livrId] ?? const [];

  LivroModel? livroDe(int livrId) {
    for (final livro in _livros) {
      if (livro.livrId == livrId) return livro;
    }
    return null;
  }

  /// Progresso do capítulo; nulo se o usuário não leu nenhum versículo dele.
  CapituloLidoModel? lidoDe(int livrId, int capiNumero) => _lidos[CapituloLidoModel.chaveDe(livrId, capiNumero)];

  /// Quantos capítulos do livro estão completos.
  int capitulosLidosDo(int livrId) => progressoDo(livrId).completos;

  /// Progresso do livro no índice (capítulos completos, começados e fração de versículos lidos).
  ProgressoLivro progressoDo(int livrId) =>
      bibliaLeituraUseCase.progressoLivro(capitulosDo(livrId), (capiNumero) => lidoDe(livrId, capiNumero));

  /// Histórico de leitura (do mais recente para o mais antigo).
  List<CapituloLidoModel> get historico => bibliaLeituraUseCase.historico(_lidos.values);

  CapituloLidoModel? get lidoAtual => switch (_capitulo) {
    final ref? => lidoDe(ref.livrId, ref.capiNumero),
    null => null,
  };

  CapituloRef? get anterior => _vizinho(-1);
  CapituloRef? get proximo => _vizinho(1);

  CapituloRef? _vizinho(int passo) {
    final ref = _capitulo;
    final indice = _indice;
    if (ref == null || indice == null) return null;
    return bibliaLeituraUseCase.vizinho(indice, _livros, ref, passo);
  }

  void selecionarTestamento(int? testId) {
    if (_testamentoId == testId) return;
    _testamentoId = testId;
    notifyListeners();
  }

  void fecharCapitulo() {
    _capitulo = null;
    _versiculos = null;
    _reacoes = const {};
    _indicacoesCapitulo = const {};
    _versiculoDestacado = null;
    _limparVersiculo();
    notifyListeners();
  }

  void _limparVersiculo() {
    _versiculoSelecionado = null;
    _indicacoes = null;
    _limparIndicados();
  }

  void _limparIndicados() {
    _indicados = const [];
    limparBuscaUsuarios(notificar: false);
  }

  /// Limpa o resultado da busca de usuários (e descarta uma busca em andamento).
  void limparBuscaUsuarios({bool notificar = true}) {
    _buscaSequencia++;
    _usuariosEncontrados = const [];
    _buscandoUsuarios = false;
    _erroBuscaUsuarios = null;
    if (notificar) notifyListeners();
  }

  /// Busca destinatários para a indicação pelo [texto] (nome ou nome de usuário). Só a resposta da busca mais
  /// recente é usada.
  Future<void> buscarUsuarios(String texto) async {
    final sequencia = ++_buscaSequencia;
    _buscandoUsuarios = true;
    _erroBuscaUsuarios = null;
    notifyListeners();

    final result = await versiculoIndicacaoUsuarioUseCase.buscar(texto, _indicados);
    if (sequencia != _buscaSequencia) return;
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final value):
        _usuariosEncontrados = value;
      case Error<List<UsuarioResumoModel>>(error: final error):
        _usuariosEncontrados = const [];
        _erroBuscaUsuarios = versiculoIndicacaoUsuarioUseCase.errorMessage(error);
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    _buscandoUsuarios = false;
    notifyListeners();
  }

  /// Carrega os destinatários da indicação [minha] do versículo [versId]; falha deixa a lista vazia.
  Future<void> _carregarIndicados(int versId, VersiculoIndicacaoModel? minha) async {
    final result = await versiculoIndicacaoUsuarioUseCase.usuarios(minha);
    if (_versiculoSelecionado?.versId != versId) return;
    switch (result) {
      case Ok<List<VersiculoIndicacaoUsuarioModel>>(value: final value):
        _indicados = value;
      case Error<List<VersiculoIndicacaoUsuarioModel>>(error: final error):
        _indicados = const [];
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  Future<Result<VersiculoIndicacaoUsuarioModel>> _adicionarIndicado(UsuarioResumoModel usuario) async {
    final versId = _versiculoSelecionado?.versId;
    final result = await versiculoIndicacaoUsuarioUseCase.adicionar(_indicacoes?.minha, usuario, _indicados);
    switch (result) {
      case Ok<VersiculoIndicacaoUsuarioModel>(value: final indicado):
        if (_versiculoSelecionado?.versId == versId) {
          _indicados = [..._indicados, indicado];
          _usuariosEncontrados = _usuariosEncontrados.where((u) => u.usuaId != usuario.usuaId).toList();
        }
      case Error<VersiculoIndicacaoUsuarioModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _removerIndicado(VersiculoIndicacaoUsuarioModel indicado) async {
    final result = await versiculoIndicacaoUsuarioUseCase.remover(indicado);
    switch (result) {
      case Ok<void>():
        _indicados = _indicados.where((i) => i.viusId != indicado.viusId).toList();
      case Error<void>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _carregar() async {
    notifyListeners();

    final (versoes, testamentos, livros) = await (
      bibliaLeituraUseCase.versoes(),
      bibliaLeituraUseCase.testamentos(),
      bibliaLeituraUseCase.livros(),
    ).wait;

    for (final Result result in [versoes, testamentos, livros]) {
      if (result case Error(error: final error)) {
        Log.print(error.toString(), name: kApp, title: 'Erro');
        notifyListeners();
        return Result.error(error);
      }
    }

    _versoes = (versoes as Ok<List<VersaoModel>>).value;
    _testamentos = (testamentos as Ok<List<TestamentoModel>>).value;
    _livros = (livros as Ok<List<LivroModel>>).value;

    final versao = _versao ?? bibliaLeituraUseCase.versaoInicial(_versoes);
    if (versao == null) {
      notifyListeners();
      return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));
    }

    final result = await _carregarVersao(versao);
    notifyListeners();
    return result;
  }

  /// Carrega índice e progresso da [versao]. Falha no progresso não impede a leitura: o índice aparece sem lidos.
  Future<Result<void>> _carregarVersao(VersaoModel versao) async {
    final (indice, lidos) = await (
      bibliaLeituraUseCase.indice(versao.versaId),
      bibliaLeituraUseCase.lidos(versao.versaId),
    ).wait;

    switch (indice) {
      case Ok<Map<int, List<IndiceCapituloModel>>>(value: final value):
        _versao = versao;
        _indice = value;
      case Error<Map<int, List<IndiceCapituloModel>>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return Result.error(error);
    }

    switch (lidos) {
      case Ok<Map<String, CapituloLidoModel>>(value: final value):
        _lidos = value;
      case Error<Map<String, CapituloLidoModel>>(error: final error):
        _lidos = const {};
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return const Result.ok(null);
  }

  Future<Result<void>> _trocarVersao(VersaoModel versao) async {
    if (versao.versaId == _versao?.versaId) return const Result.ok(null);
    notifyListeners();

    final result = await _carregarVersao(versao);
    if (result is Ok) {
      bibliaLeituraUseCase.salvarVersao(versao);
      final ref = _capitulo;
      // O capítulo aberto é recarregado na nova versão; se ela não tem o capítulo, volta ao índice.
      if (ref != null) {
        final existe = capitulosDo(ref.livrId).any((c) => c.capiNumero == ref.capiNumero);
        if (existe) {
          await _abrirCapitulo(ref);
        } else {
          fecharCapitulo();
        }
      }
    }

    notifyListeners();
    return result;
  }

  Future<Result<List<VersiculoTextoModel>>> _abrirCapitulo(CapituloRef ref) async {
    final versao = _versao;
    if (versao == null) {
      return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));
    }
    _capitulo = ref;
    _versiculos = null;
    _reacoes = const {};
    _indicacoesCapitulo = const {};
    _versiculoDestacado = null;
    _limparVersiculo();
    notifyListeners();

    final (result, reacoes, indicacoes) = await (
      bibliaLeituraUseCase.capitulo(versao.versaId, ref),
      bibliaLeituraUseCase.reacoesCapitulo(versao.versaId, ref),
      versiculoIndicacaoUseCase.indicacoesCapitulo(versao.versaId, ref.livrId, ref.capiNumero),
    ).wait;
    // Ignora a resposta se outro capítulo foi aberto enquanto este carregava.
    final atual = _capitulo == ref;
    switch (result) {
      case Ok<List<VersiculoTextoModel>>(value: final versiculos):
        if (atual) _versiculos = versiculos;
      case Error<List<VersiculoTextoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    // Falha nas reações não impede a leitura: os versículos aparecem sem marcação.
    switch (reacoes) {
      case Ok<Map<int, VersiculoReacaoModel>>(value: final value):
        if (atual) _reacoes = value;
      case Error<Map<int, VersiculoReacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    // Falha nas indicações também não impede a leitura: os ícones aparecem como não indicados.
    switch (indicacoes) {
      case Ok<Map<int, VersiculoIndicacaoModel>>(value: final value):
        if (atual) _indicacoesCapitulo = value;
      case Error<Map<int, VersiculoIndicacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  /// Recarrega as reações do capítulo aberto (depois de marcar ou desmarcar o capítulo inteiro).
  Future<void> _recarregarReacoes() async {
    final versao = _versao;
    final ref = _capitulo;
    if (versao == null || ref == null) return;
    final result = await bibliaLeituraUseCase.reacoesCapitulo(versao.versaId, ref);
    switch (result) {
      case Ok<Map<int, VersiculoReacaoModel>>(value: final value):
        if (_capitulo == ref) _reacoes = value;
      case Error<Map<int, VersiculoReacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  Future<Result<VersiculoReacaoModel>> _marcarVersiculo(VersiculoTextoModel versiculo) async {
    final ref = _capitulo;
    _versiculoGravando = versiculo.versId;
    notifyListeners();

    final result = await versiculoReacaoUseCase.alternarLido(
      versiculo.versId,
      _reacoes[versiculo.versId],
      manterComentario: true,
    );
    switch (result) {
      case Ok<VersiculoReacaoModel>(value: final reacao):
        if (ref != null && _capitulo == ref) {
          _reacoes = {..._reacoes, reacao.versId: reacao};
          final capitulo = capitulosDo(ref.livrId).where((c) => c.capiNumero == ref.capiNumero).firstOrNull;
          final chave = CapituloLidoModel.chaveDe(ref.livrId, ref.capiNumero);
          final antes = _lidos[chave];
          if (capitulo != null) {
            final progresso = bibliaLeituraUseCase.progressoCapitulo(capitulo, livroDe(ref.livrId), _reacoes);
            _lidos = {..._lidos}..remove(chave);
            if (progresso != null) _lidos[chave] = progresso;
          }
          _feedback = bibliaLeituraUseCase.mensagemVersiculo(
            lido: reacao.vreaLido,
            antes: antes,
            depois: _lidos[chave],
          );
        }
      case Error<VersiculoReacaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    _versiculoGravando = null;
    notifyListeners();
    return result;
  }

  Future<Result<CapituloLidoModel?>> _marcarLido() async {
    final versao = _versao;
    final ref = _capitulo;
    final capitulo = ref == null
        ? null
        : capitulosDo(ref.livrId).where((c) => c.capiNumero == ref.capiNumero).firstOrNull;
    if (versao == null || ref == null || capitulo == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    notifyListeners();

    final result = await bibliaLeituraUseCase.alternarCapitulo(
      versao.versaId,
      capitulo,
      livroDe(ref.livrId),
      lidoDe(ref.livrId, ref.capiNumero),
    );
    switch (result) {
      case Ok<CapituloLidoModel?>(value: final lido):
        final chave = CapituloLidoModel.chaveDe(ref.livrId, ref.capiNumero);
        _lidos = {..._lidos}..remove(chave);
        if (lido != null) _lidos[chave] = lido;
        _feedback = bibliaLeituraUseCase.mensagemCapitulo(lido);
        await _recarregarReacoes();
      case Error<CapituloLidoModel?>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<IndicacoesVersiculo>> _carregarIndicacoes(VersiculoTextoModel versiculo) async {
    _versiculoSelecionado = versiculo;
    _indicacoes = null;
    _limparIndicados();
    notifyListeners();

    final result = await versiculoIndicacaoUseCase.indicacoes(versiculo.versId);
    switch (result) {
      case Ok<IndicacoesVersiculo>(value: final value):
        if (_versiculoSelecionado?.versId == versiculo.versId) {
          await _carregarIndicados(versiculo.versId, value.minha);
          if (_versiculoSelecionado?.versId == versiculo.versId) _indicacoes = value;
        }
      case Error<IndicacoesVersiculo>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<VersiculoIndicacaoModel>> _indicar(String? comentario) async {
    final versiculo = _versiculoSelecionado;
    if (versiculo == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    notifyListeners();

    final atual = _indicacoes?.minha;
    final result = await versiculoIndicacaoUseCase.indicar(versiculo.versId, atual, comentario: comentario);
    switch (result) {
      case Ok<VersiculoIndicacaoModel>(value: final indicacao):
        if (_versiculoSelecionado?.versId == indicacao.versId) {
          final total = _indicacoes?.total ?? 0;
          _indicacoes = (total: atual == null ? total + 1 : total, minha: indicacao);
        }
        if (_versiculos?.any((v) => v.versId == indicacao.versId) ?? false) {
          _indicacoesCapitulo = {..._indicacoesCapitulo, indicacao.versId: indicacao};
        }
      case Error<VersiculoIndicacaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<void>> _removerIndicacao() async {
    final atual = _indicacoes?.minha;
    if (atual == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    notifyListeners();

    final result = await versiculoIndicacaoUseCase.remover(atual);
    switch (result) {
      case Ok<void>():
        final total = _indicacoes?.total ?? 1;
        _indicacoes = (total: total > 0 ? total - 1 : 0, minha: null);
        _indicacoesCapitulo = {..._indicacoesCapitulo}..remove(atual.versId);
        _limparIndicados();
      case Error<void>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    versaoCommand.dispose();
    abrirCapituloCommand.dispose();
    marcarLidoCommand.dispose();
    marcarVersiculoCommand.dispose();
    indicacoesCommand.dispose();
    indicarCommand.dispose();
    removerIndicacaoCommand.dispose();
    adicionarIndicadoCommand.dispose();
    removerIndicadoCommand.dispose();
    super.dispose();
  }
}
