import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/fale_conosco/fale_conosco_atendimento_model.dart';
import '../../fale_conosco/use_case/fale_conosco_usecase.dart';
import '../use_case/fale_conosco_atendimento_usecase.dart';

/// Ações de um toque sobre o chamado aberto (todas gravam no `PUT`).
enum FaleConoscoAtendimentoAcao { assumir, liberar, fechar, reabrir }

/// Estado da tela "Atendimento do Fale conosco".
///
/// - [carregarCommand] (executado ao criar) busca as opções (só na primeira vez) e a fila do [filtro]; uma atualização
///   que falha mantém a última fila. [selecionarSituacao] e [alternarMeus] trocam o filtro e recarregam.
/// - [detalheCommand] abre um chamado com as interações ([detalhe]).
/// - [responderCommand], [classificarCommand], [acaoCommand] e [excluirCommand] gravam no chamado aberto, trocam o
///   [detalhe] pelo devolvido e recarregam a fila (o chamado pode sair do filtro).
class FaleConoscoAtendimentoViewmodel extends ChangeNotifier {
  FaleConoscoAtendimentoViewmodel({required this.faleConoscoAtendimentoUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final FaleConoscoAtendimentoUseCase faleConoscoAtendimentoUseCase;

  late final Command0<List<FaleConoscoAtendimentoModel>> carregarCommand = Command0(_carregar);
  late final Command1<FaleConoscoAtendimentoDetalhe, int> detalheCommand = Command1(_abrir);
  late final Command1<FaleConoscoAtendimentoDetalhe, FaleConoscoAtendimentoResposta> responderCommand = Command1(
    _responder,
  );
  late final Command1<FaleConoscoAtendimentoModel, FaleConoscoAtendimentoClassificacao> classificarCommand = Command1(
    (c) => _atualizar((u, chamado) => u.classificar(chamado, c)),
  );
  late final Command1<FaleConoscoAtendimentoModel, FaleConoscoAtendimentoAcao> acaoCommand = Command1(
    (acao) => _atualizar(
      (u, chamado) => switch (acao) {
        FaleConoscoAtendimentoAcao.assumir => u.assumir(chamado),
        FaleConoscoAtendimentoAcao.liberar => u.liberar(chamado),
        FaleConoscoAtendimentoAcao.fechar => u.fechar(chamado, opcoes),
        FaleConoscoAtendimentoAcao.reabrir => u.reabrir(chamado, opcoes),
      },
    ),
  );
  late final Command0<void> excluirCommand = Command0(_excluir);

  FaleConoscoAtendimentoOpcoes? _opcoes;
  List<FaleConoscoAtendimentoModel>? _fila;
  FaleConoscoAtendimentoDetalhe? _aberto;
  FaleConoscoAtendimentoFiltro _filtro = (situacao: null, meus: false);

  FaleConoscoAtendimentoOpcoes get opcoes => _opcoes ?? const FaleConoscoAtendimentoOpcoes();

  /// Chamados do filtro; nula até o primeiro carregamento concluir.
  List<FaleConoscoAtendimentoModel>? get fila => _fila;

  FaleConoscoAtendimentoFiltro get filtro => _filtro;

  /// Chamado aberto; nulo enquanto carrega.
  FaleConoscoAtendimentoDetalhe? get detalhe => _aberto;

  bool get gravando =>
      responderCommand.running || classificarCommand.running || acaoCommand.running || excluirCommand.running;

  int get textoMaximo => FaleConoscoAtendimentoUseCase.textoMaximo;

  int? get usuarioId => faleConoscoAtendimentoUseCase.usuarioId;

  /// O chamado aberto é do usuário logado.
  bool get meuChamado => usuarioId != null && _aberto?.chamado.fconResponsavelId == usuarioId;

  void selecionarSituacao(int? situacao) {
    if (situacao == _filtro.situacao) return;
    _filtro = (situacao: situacao, meus: _filtro.meus);
    carregarCommand.execute();
  }

  void alternarMeus() {
    _filtro = (situacao: _filtro.situacao, meus: !_filtro.meus);
    carregarCommand.execute();
  }

  /// Limpa o detalhe antes de abrir outro chamado.
  void fecharDetalhe() {
    _aberto = null;
    for (final Command c in [detalheCommand, responderCommand, classificarCommand, acaoCommand, excluirCommand]) {
      c.clearResult();
    }
  }

  String? validarResposta(String texto) => FaleConoscoAtendimentoUseCase.validarResposta(texto);

  String categoria(int chave) => FaleConoscoAtendimentoUseCase.rotulo(opcoes.categorias, chave);
  String prioridade(int chave) => FaleConoscoAtendimentoUseCase.rotulo(opcoes.prioridades, chave);
  String situacao(int? chave) => FaleConoscoAtendimentoUseCase.rotulo(opcoes.situacoes, chave);
  String origem(int? chave) => FaleConoscoAtendimentoUseCase.rotulo(opcoes.origens, chave);

  double? nivelPrioridade(int chave) => FaleConoscoAtendimentoUseCase.nivelPrioridade(opcoes.prioridades, chave);

  String? data(DateTime? quando) => FaleConoscoAtendimentoUseCase.data(quando);

  String? duracao(int? segundos) => FaleConoscoAtendimentoUseCase.duracao(segundos);

  String mensagemErro(Exception error) => FaleConoscoAtendimentoUseCase.mensagemErro(error);

  Future<Result<List<FaleConoscoAtendimentoModel>>> _carregar() async {
    notifyListeners();
    if (_opcoes == null) {
      final opcoes = await faleConoscoAtendimentoUseCase.opcoes();
      switch (opcoes) {
        case Ok(value: final value):
          _opcoes = value;
        case Error(error: final error):
          Log.print(error.toString(), name: kApp, title: 'Erro');
          notifyListeners();
          return Result.error(error);
      }
    }
    final result = await faleConoscoAtendimentoUseCase.fila(_filtro);
    switch (result) {
      case Ok(value: final value):
        _fila = value;
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  /// Recarrega a fila sem passar pelo [carregarCommand] (depois de uma gravação).
  Future<void> _recarregarFila() async {
    if (await faleConoscoAtendimentoUseCase.fila(_filtro) case Ok(value: final value)) _fila = value;
  }

  Future<Result<FaleConoscoAtendimentoDetalhe>> _abrir(int fconId) async {
    _aberto = null;
    notifyListeners();
    final result = await faleConoscoAtendimentoUseCase.detalhe(fconId);
    switch (result) {
      case Ok(value: final value):
        _aberto = value;
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<FaleConoscoAtendimentoDetalhe>> _responder(FaleConoscoAtendimentoResposta resposta) async {
    final aberto = _aberto;
    if (aberto == null) return Result.error(HandledException(message: kDefaultAppError));
    notifyListeners();
    final result = await faleConoscoAtendimentoUseCase.responder(aberto.chamado, resposta);
    switch (result) {
      case Ok(value: final value):
        _aberto = value;
        await _recarregarFila();
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  /// Grava no chamado aberto e troca o chamado do detalhe pelo devolvido (as interações não mudam).
  Future<Result<FaleConoscoAtendimentoModel>> _atualizar(
    Future<Result<FaleConoscoAtendimentoModel>> Function(FaleConoscoAtendimentoUseCase, FaleConoscoAtendimentoModel)
    gravar,
  ) async {
    final aberto = _aberto;
    if (aberto == null) return Result.error(HandledException(message: kDefaultAppError));
    notifyListeners();
    final result = await gravar(faleConoscoAtendimentoUseCase, aberto.chamado);
    switch (result) {
      case Ok(value: final chamado):
        _aberto = FaleConoscoAtendimentoDetalhe(chamado: chamado, interacoes: aberto.interacoes);
        await _recarregarFila();
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _excluir() async {
    final aberto = _aberto;
    if (aberto == null) return Result.error(HandledException(message: kDefaultAppError));
    notifyListeners();
    final result = await faleConoscoAtendimentoUseCase.excluir(aberto.chamado);
    switch (result) {
      case Ok():
        _aberto = null;
        _fila = [
          for (final c in _fila ?? const <FaleConoscoAtendimentoModel>[])
            if (c.fconId != aberto.chamado.fconId) c,
        ];
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    detalheCommand.dispose();
    responderCommand.dispose();
    classificarCommand.dispose();
    acaoCommand.dispose();
    excluirCommand.dispose();
    super.dispose();
  }
}

/// Reexporta o tipo das opções para a view não depender do use case do solicitante.
typedef FaleConoscoAtendimentoOpcao = FaleConoscoOpcao;
