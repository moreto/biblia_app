import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../config/command.dart';
import '../../../data/model/menu/menu_model.dart';
import '../use_case/dashboard_usecase.dart';

/// Estado da dashboard: menus ([menuCommand]) e quantidade de mensagens não lidas do badge ([naoLidasCommand]).
/// Os dois carregam no construtor. A view recarrega as não lidas ao voltar de uma tela aberta pelo menu.
class DashboardViewmodel extends ChangeNotifier {
  DashboardViewmodel({required this._dashboardUseCase}) {
    Log.print(super.runtimeType);
    menuCommand.execute();
    naoLidasCommand.execute();
  }

  final DashboardUseCase _dashboardUseCase;

  late final Command0<MenuModel> menuCommand = Command0(_menu);
  MenuModel? _menuModel;
  MenuModel? get menuModel => _menuModel;

  /// Recarrega a quantidade de mensagens não lidas. Erro não aparece para o usuário (só no log) e mantém o último
  /// valor carregado.
  late final Command0<int> naoLidasCommand = Command0(_naoLidas);
  int _mensagensNaoLidas = 0;
  int get mensagensNaoLidas => _mensagensNaoLidas;

  /// Texto do badge do menu de mensagens; nulo quando não há não lidas.
  String? get rotuloBadge => DashboardUseCase.rotuloBadge(_mensagensNaoLidas);

  Future<Result<MenuModel>> _menu() async {
    notifyListeners();

    final result = await _dashboardUseCase.menu();
    switch (result) {
      case Ok<MenuModel>():
        _menuModel = result.value;
      case Error<MenuModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<int>> _naoLidas() async {
    final result = await _dashboardUseCase.mensagensNaoLidas();
    switch (result) {
      case Ok<int>(value: final total):
        _mensagensNaoLidas = total;
      case Error<int>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }
}
