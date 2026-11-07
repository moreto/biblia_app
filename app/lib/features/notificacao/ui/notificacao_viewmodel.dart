import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/notificacao_model.dart';
import '../use_case/notificacao_usecase.dart';

class NotificacaoViewmodel extends ChangeNotifier {
  NotificacaoViewmodel({required this.notificacaoUseCase}) {
    Log.print(super.runtimeType);
    getNotificacoesCommand.execute();
  }

  final NotificacaoUseCase notificacaoUseCase;

  late final Command0<List<NotificacaoModel>> getNotificacoesCommand = Command0(_getNotificacoes);
  List<NotificacaoModel>? _notificacoes;
  List<NotificacaoModel>? get notificacoes => _notificacoes;

  Future<Result<List<NotificacaoModel>>> _getNotificacoes() async {
    notifyListeners();

    final result = await notificacaoUseCase.getNotificacoes();
    switch (result) {
      case Ok<List<NotificacaoModel>>():
        _notificacoes = result.value;
      case Error<List<NotificacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }
}
