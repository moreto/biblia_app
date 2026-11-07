import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import '../use_case/biblia_leitura_usecase.dart';

/// Estado da leitura da Bíblia.
///
/// Ao ser criado executa [carregarCommand]: versões, testamentos e livros e, para a versão escolhida (a primeira),
/// o índice de capítulos e o progresso de leitura do usuário. A partir daí:
/// - [versaoCommand] troca a versão e recarrega índice, progresso e o capítulo aberto;
/// - [selecionarTestamento] filtra os livros do índice (nulo = todos);
/// - [abrirCapituloCommand] carrega os versículos de um capítulo; [fecharCapitulo] volta ao índice;
/// - [marcarLidoCommand] marca o capítulo aberto como lido (ou desmarca, se já estava completo);
/// - [indicacoesCommand], [indicarCommand] e [removerIndicacaoCommand] tratam a indicação do versículo selecionado.
class BibliaLeituraViewmodel extends ChangeNotifier {
  BibliaLeituraViewmodel({required this.bibliaLeituraUseCase, required this.versiculoIndicacaoUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
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
  int capitulosLidosDo(int livrId) =>
      capitulosDo(livrId).where((c) => lidoDe(livrId, c.capiNumero)?.completo ?? false).length;

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
    _limparVersiculo();
    notifyListeners();
  }

  void _limparVersiculo() {
    _versiculoSelecionado = null;
    _indicacoes = null;
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

    final versao = _versao ?? (_versoes.isEmpty ? null : _versoes.first);
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
    _limparVersiculo();
    notifyListeners();

    final result = await bibliaLeituraUseCase.capitulo(versao.versaId, ref);
    switch (result) {
      case Ok<List<VersiculoTextoModel>>(value: final versiculos):
        // Ignora a resposta se outro capítulo foi aberto enquanto este carregava.
        if (_capitulo == ref) _versiculos = versiculos;
      case Error<List<VersiculoTextoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

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
      case Error<CapituloLidoModel?>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<IndicacoesVersiculo>> _carregarIndicacoes(VersiculoTextoModel versiculo) async {
    _versiculoSelecionado = versiculo;
    _indicacoes = null;
    notifyListeners();

    final result = await versiculoIndicacaoUseCase.indicacoes(versiculo.versId);
    switch (result) {
      case Ok<IndicacoesVersiculo>(value: final value):
        if (_versiculoSelecionado?.versId == versiculo.versId) _indicacoes = value;
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
    indicacoesCommand.dispose();
    indicarCommand.dispose();
    removerIndicacaoCommand.dispose();
    super.dispose();
  }
}
