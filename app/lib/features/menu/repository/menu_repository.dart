import 'package:commons/commons.dart';

import '../../../data/model/menu/menu_item_model.dart';

abstract class MenuRepository {
  /// Hierarquia dos itens ativos (raízes com os filhos em `children`).
  Future<Result<List<MenuItemModel>>> getMenus();
  Future<Result<MenuItemModel>> insertMenu(MenuItemModel menu);
  Future<Result<MenuItemModel>> updateMenu(MenuItemModel menu);
  Future<Result<int>> deleteMenu(int menuId);
}
