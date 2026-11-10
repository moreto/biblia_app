import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/renomado_model.dart';
import '../use_case/renomado_usecase.dart';

class RenomadoViewmodel extends ChangeNotifier {
  RenomadoViewmodel({required this.renomadoUseCase}) {
    Log.print(super.runtimeType);
    listarCommand.execute();
  }

  final RenomadoUseCase renomadoUseCase;

  late final Command0<List<RenomadoModel>> listarCommand = Command0(_listar);

  /// Nulo até o primeiro carregamento concluir. Uma atualização que falha mantém a última lista carregada.
  List<RenomadoModel>? _renomados;
  List<RenomadoModel>? get renomados => _renomados;

  Future<Result<List<RenomadoModel>>> _listar() async {
    notifyListeners();

    final result = await renomadoUseCase.listar();
    switch (result) {
      case Ok<List<RenomadoModel>>():
        _renomados = result.value;
      case Error<List<RenomadoModel>>(error: final error):
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
