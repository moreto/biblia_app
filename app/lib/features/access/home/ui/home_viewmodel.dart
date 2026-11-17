import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../use_case/home_usecase.dart';

/// Estado da tela de entrada: o id do aparelho, carregado ao abrir a tela.
class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel({required this.homeUseCase}) {
    idDispositivoCommand.execute();
  }

  final HomeUseCase homeUseCase;

  late final Command0<String> idDispositivoCommand = Command0(_carregarIdDispositivo);

  String? _idDispositivo;

  /// Id do aparelho; null enquanto carrega ou se não foi possível ler.
  String? get idDispositivo => _idDispositivo;

  Future<Result<String>> _carregarIdDispositivo() async {
    final result = await homeUseCase.idDispositivo();
    if (result case Ok(value: final id)) _idDispositivo = id;
    notifyListeners();
    return result;
  }
}
