import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/versiculo_indicado_model.dart';
import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../use_case/versiculo_indicado_usecase.dart';

/// Estado da tela "Indicações recebidas": [carregarCommand] (executado ao criar) busca as indicações; uma
/// atualização que falha mantém a última lista.
class VersiculoIndicadoViewmodel extends ChangeNotifier {
  VersiculoIndicadoViewmodel({required this.versiculoIndicadoUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final VersiculoIndicadoUseCase versiculoIndicadoUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);

  List<VersiculoIndicadoModel>? _recebidas;

  /// Indicações recebidas; nula até o primeiro carregamento concluir.
  List<VersiculoIndicadoModel>? get recebidas => _recebidas;

  LeituraDestino destino(VersiculoIndicadoModel indicacao) => VersiculoIndicadoUseCase.destino(indicacao);

  String referencia(VersiculoIndicadoModel indicacao) => VersiculoIndicadoUseCase.referencia(indicacao);

  String? quemIndicou(VersiculoIndicadoModel indicacao) => VersiculoIndicadoUseCase.quemIndicou(indicacao);

  String? comentario(VersiculoIndicadoModel indicacao) => VersiculoIndicadoUseCase.comentario(indicacao);

  String? data(VersiculoIndicadoModel indicacao) => VersiculoIndicadoUseCase.data(indicacao);

  String mensagemErro(Exception error) => VersiculoIndicadoUseCase.mensagemErro(error);

  Future<Result<void>> _carregar() async {
    notifyListeners();
    final result = await versiculoIndicadoUseCase.recebidas();
    switch (result) {
      case Ok<List<VersiculoIndicadoModel>>(value: final value):
        _recebidas = value;
      case Error<List<VersiculoIndicadoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    super.dispose();
  }
}
