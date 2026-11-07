import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../config/command.dart';
import '../../../data/model/menu/menu_model.dart';
import '../use_case/dashboard_usecase.dart';

class DashboardViewmodel extends ChangeNotifier {
  DashboardViewmodel({required this._dashboardUseCase}) {
    Log.print(super.runtimeType);
    menuCommand.execute();
  }

  final DashboardUseCase _dashboardUseCase;

  late final Command0<MenuModel> menuCommand = Command0(_menu);
  MenuModel? _menuModel;
  MenuModel? get menuModel => _menuModel;

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
}
