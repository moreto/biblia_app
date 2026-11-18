import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../../../data/model/funcionalidade/funcionalidade_model.dart';
import '../use_case/funcionalidade_usecase.dart';

/// Estado do card de funcionalidades da home: carrega a lista ao ser criado e de novo a cada
/// `listarCommand.execute()`.
class FuncionalidadeViewmodel extends ChangeNotifier {
  FuncionalidadeViewmodel({required this.funcionalidadeUseCase}) {
    Log.print(super.runtimeType);
    listarCommand.execute();
  }

  final FuncionalidadeUseCase funcionalidadeUseCase;

  late final Command0<List<FuncionalidadeModel>> listarCommand = Command0(_listar);

  /// Nula até o primeiro carregamento concluir (ou quando ele falha).
  List<FuncionalidadeModel>? _funcionalidades;
  List<FuncionalidadeModel>? get funcionalidades => _funcionalidades;

  Future<Result<List<FuncionalidadeModel>>> _listar() async {
    notifyListeners();

    final result = await funcionalidadeUseCase.listar();
    switch (result) {
      case Ok<List<FuncionalidadeModel>>():
        _funcionalidades = result.value;
      case Error<List<FuncionalidadeModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    listarCommand.dispose();
    super.dispose();
  }
}
