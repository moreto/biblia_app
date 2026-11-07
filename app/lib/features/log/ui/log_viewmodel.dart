import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/log_model.dart';
import '../use_case/log_usecase.dart';

class LogViewmodel extends ChangeNotifier {
  LogViewmodel({required this.logUseCase}) {
    Log.print(super.runtimeType);
    getLogsCommand.execute();
  }

  final LogUseCase logUseCase;

  late final Command0<List<LogModel>> getLogsCommand = Command0(_getLogs);
  List<LogModel>? _logs;
  List<LogModel>? get logs => _logs;

  Future<Result<List<LogModel>>> _getLogs() async {
    notifyListeners();

    final result = await logUseCase.getLogs();
    switch (result) {
      case Ok<List<LogModel>>():
        _logs = result.value;
      case Error<List<LogModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }
}
