import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/oracao/oracao_model.dart';
import '../use_case/oracao_usecase.dart';

/// Estado do card de oração da dashboard: carrega uma oração ao ser criado e sorteia outra a cada
/// `aleatoriaCommand.execute()`.
class OracaoViewmodel extends ChangeNotifier {
  OracaoViewmodel({required this.oracaoUseCase}) {
    Log.print(super.runtimeType);
    aleatoriaCommand.execute();
  }

  final OracaoUseCase oracaoUseCase;

  late final Command0<OracaoModel> aleatoriaCommand = Command0(_aleatoria);

  /// Última oração carregada; continua visível enquanto outra é sorteada ou se o novo sorteio falhar.
  OracaoModel? _oracao;
  OracaoModel? get oracao => _oracao;

  /// Mostra o texto completo da oração (o card começa recolhido).
  bool _expandida = false;
  bool get expandida => _expandida;

  void alternarExpandida() {
    _expandida = !_expandida;
    notifyListeners();
  }

  Future<Result<OracaoModel>> _aleatoria() async {
    notifyListeners();

    final result = await oracaoUseCase.aleatoria();
    switch (result) {
      case Ok<OracaoModel>():
        _oracao = result.value;
        _expandida = false;
      case Error<OracaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    aleatoriaCommand.dispose();
    super.dispose();
  }
}
