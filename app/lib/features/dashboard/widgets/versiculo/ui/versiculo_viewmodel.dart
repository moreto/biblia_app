import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/versiculo/versiculo_model.dart';
import '../use_case/versiculo_usecase.dart';

/// Estado do card de versículo da dashboard: carrega um versículo ao ser criado e sorteia outro a cada
/// `aleatorioCommand.execute()`.
class VersiculoViewmodel extends ChangeNotifier {
  VersiculoViewmodel({required this.versiculoUseCase}) {
    Log.print(super.runtimeType);
    aleatorioCommand.execute();
  }

  final VersiculoUseCase versiculoUseCase;

  late final Command0<VersiculoModel> aleatorioCommand = Command0(_aleatorio);

  /// Último versículo carregado; continua visível enquanto outro é sorteado ou se o novo sorteio falhar.
  VersiculoModel? _versiculo;
  VersiculoModel? get versiculo => _versiculo;

  Future<Result<VersiculoModel>> _aleatorio() async {
    notifyListeners();

    final result = await versiculoUseCase.aleatorio();
    switch (result) {
      case Ok<VersiculoModel>():
        _versiculo = result.value;
      case Error<VersiculoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    aleatorioCommand.dispose();
    super.dispose();
  }
}
