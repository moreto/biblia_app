import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/fale_conosco/fale_conosco_model.dart';
import '../use_case/fale_conosco_usecase.dart';

/// Estado da tela "Fale conosco".
///
/// - [carregarCommand] (executado ao criar) busca os chamados e as opções; uma atualização que falha mantém os
///   últimos dados.
/// - [enviarCommand] abre um chamado e, se der certo, recarrega a lista.
/// - [detalheCommand] abre um chamado com as interações ([detalhe]); [responderCommand] grava a mensagem do usuário
///   nele e troca o [detalhe] pelo atualizado (e o chamado da lista também).
class FaleConoscoViewmodel extends ChangeNotifier {
  FaleConoscoViewmodel({required this.faleConoscoUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final FaleConoscoUseCase faleConoscoUseCase;

  late final Command0<FaleConoscoDados> carregarCommand = Command0(_carregar);
  late final Command1<FaleConoscoEnvioModel, FaleConoscoFormulario> enviarCommand = Command1(_enviar);
  late final Command1<FaleConoscoModel, int> detalheCommand = Command1(_detalhe);
  late final Command1<FaleConoscoModel, String> responderCommand = Command1(_responder);

  FaleConoscoDados? _dados;
  FaleConoscoModel? _aberto;

  /// Chamados e opções; nulo até o primeiro carregamento concluir.
  FaleConoscoDados? get dados => _dados;

  List<FaleConoscoModel> get chamados => _dados?.chamados ?? const [];

  FaleConoscoOpcoes get opcoes => _dados?.opcoes ?? const FaleConoscoOpcoes();

  /// Chamado aberto no detalhe (com as interações); nulo enquanto carrega.
  FaleConoscoModel? get detalhe => _aberto;

  bool get ocupado => carregarCommand.running || enviarCommand.running;

  String get prefixoNome => faleConoscoUseCase.prefixoNome;

  String get prefixoEmail => faleConoscoUseCase.prefixoEmail;

  int get nomeMaximo => FaleConoscoUseCase.nomeMaximo;
  int get emailMaximo => FaleConoscoUseCase.emailMaximo;
  int get telefoneMaximo => FaleConoscoUseCase.telefoneMaximo;
  int get assuntoMaximo => FaleConoscoUseCase.assuntoMaximo;
  int get textoMaximo => FaleConoscoUseCase.textoMaximo;

  String? validar(FaleConoscoFormulario formulario) => FaleConoscoUseCase.validar(formulario);

  /// Rótulos (chaves de tradução) da categoria e da situação.
  String categoria(int chave) => FaleConoscoUseCase.rotulo(opcoes.categorias, chave);

  String situacao(int? chave) => FaleConoscoUseCase.rotulo(opcoes.situacoes, chave);

  String? data(DateTime? quando) => FaleConoscoUseCase.data(quando);

  String mensagemErro(Exception error) => FaleConoscoUseCase.mensagemErro(error);

  /// Limpa o detalhe antes de abrir outro chamado.
  void fecharDetalhe() {
    _aberto = null;
    detalheCommand.clearResult();
    responderCommand.clearResult();
  }

  Future<Result<FaleConoscoDados>> _carregar() async {
    notifyListeners();
    final result = await faleConoscoUseCase.carregar();
    switch (result) {
      case Ok<FaleConoscoDados>(value: final value):
        _dados = value;
      case Error<FaleConoscoDados>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<FaleConoscoEnvioModel>> _enviar(FaleConoscoFormulario formulario) async {
    notifyListeners();
    final result = await faleConoscoUseCase.enviar(formulario, opcoes);
    switch (result) {
      case Ok<FaleConoscoEnvioModel>():
        if (await faleConoscoUseCase.carregar() case Ok(value: final atual)) _dados = atual;
      case Error<FaleConoscoEnvioModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<FaleConoscoModel>> _detalhe(int fconId) async {
    _aberto = null;
    notifyListeners();
    final result = await faleConoscoUseCase.detalhe(fconId);
    _aplicarDetalhe(result);
    notifyListeners();
    return result;
  }

  Future<Result<FaleConoscoModel>> _responder(String texto) async {
    final chamado = _aberto;
    if (chamado == null) return Result.error(HandledException(message: kDefaultAppError));
    notifyListeners();
    final result = await faleConoscoUseCase.responder(chamado, texto);
    _aplicarDetalhe(result);
    notifyListeners();
    return result;
  }

  /// Guarda o chamado como [detalhe] e o troca na lista.
  void _aplicarDetalhe(Result<FaleConoscoModel> result) {
    switch (result) {
      case Ok<FaleConoscoModel>(value: final chamado):
        _aberto = chamado;
        final dados = _dados;
        if (dados != null) {
          _dados = FaleConoscoDados(
            chamados: [for (final c in dados.chamados) c.fconId == chamado.fconId ? chamado : c],
            opcoes: dados.opcoes,
          );
        }
      case Error<FaleConoscoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    enviarCommand.dispose();
    detalheCommand.dispose();
    responderCommand.dispose();
    super.dispose();
  }
}
