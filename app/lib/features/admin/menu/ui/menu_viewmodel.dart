import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/menu/menu_item_model.dart';
import '../use_case/menu_usecase.dart';

class MenuViewmodel extends ChangeNotifier {
  MenuViewmodel({required this.menuUseCase}) {
    Log.print(super.runtimeType);
    getMenusCommand.execute();
  }

  final MenuUseCase menuUseCase;

  late final Command0<List<MenuNivelModel>> getMenusCommand = Command0(_getMenus);
  late final Command1<MenuItemModel, MenuItemModel> saveMenuCommand = Command1(_saveMenu);
  late final Command1<int, MenuItemModel> deleteMenuCommand = Command1(_deleteMenu);

  List<MenuNivelModel>? _menus;
  List<MenuNivelModel>? get menus => _menus;

  final Set<int> _recolhidos = {};

  /// Itens exibidos na lista, respeitando os itens recolhidos.
  List<MenuNivelModel>? get menusVisiveis {
    final menus = _menus;
    return menus == null ? null : menuUseCase.visiveis(menus, _recolhidos);
  }

  bool isRecolhido(MenuItemModel menu) => _recolhidos.contains(menu.menuId);

  void alternarRecolhido(MenuItemModel menu) {
    final menuId = menu.menuId;
    if (menuId == null) return;
    if (!_recolhidos.remove(menuId)) _recolhidos.add(menuId);
    notifyListeners();
  }

  List<MenuItemModel> opcoesPai(MenuItemModel? menu) => menuUseCase.opcoesPai(_menus ?? const [], menu);

  Future<Result<List<MenuNivelModel>>> _getMenus() async {
    notifyListeners();

    final result = await menuUseCase.getMenus();
    switch (result) {
      case Ok<List<MenuNivelModel>>():
        _menus = result.value;
        _recolhidos.retainAll(result.value.map((item) => item.menu.menuId));
      case Error<List<MenuNivelModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<MenuItemModel>> _saveMenu(MenuItemModel menu) async {
    notifyListeners();

    final result = await menuUseCase.saveMenu(menu);
    switch (result) {
      case Ok<MenuItemModel>():
        // garante o novo filho visível
        final parentId = result.value.menuParentId;
        if (parentId != null) _recolhidos.remove(parentId);
        getMenusCommand.execute();
      case Error<MenuItemModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<int>> _deleteMenu(MenuItemModel menu) async {
    notifyListeners();

    final result = await menuUseCase.deleteMenu(menu);
    switch (result) {
      case Ok<int>():
        getMenusCommand.execute();
      case Error<int>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    getMenusCommand.dispose();
    saveMenuCommand.dispose();
    deleteMenuCommand.dispose();
    super.dispose();
  }
}
