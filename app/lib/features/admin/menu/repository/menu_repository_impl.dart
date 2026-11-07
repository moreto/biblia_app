import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/menu/menu_item_model.dart';
import 'menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  @override
  Future<Result<List<MenuItemModel>>> getMenus() async {
    try {
      final response = await DioProvider.of(ApiCore.menu).request(verb: Verb.get);
      switch (response) {
        // `menu` vem nulo quando não há itens ativos
        case Ok(value: final value) when value is Map:
          final menus = value['menu'];
          if (menus == null) return Result.ok(const []);
          if (menus is! List) return Result.error(HandledException(message: 'formatoMenuInvalido'));
          return Result.ok(
            menus.map((item) => MenuItemModel.fromJson(Map<String, dynamic>.from(item as Map))).toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoMenuInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoMenuInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  @override
  Future<Result<MenuItemModel>> insertMenu(MenuItemModel menu) => _requestOne(Verb.post, menu.toJson());

  @override
  Future<Result<MenuItemModel>> updateMenu(MenuItemModel menu) => _requestOne(Verb.put, menu.toJson());

  @override
  Future<Result<int>> deleteMenu(int menuId) async {
    try {
      final response = await DioProvider.of(ApiCore.menu).request(verb: Verb.delete, pathParam: menuId);
      switch (response) {
        case Ok(value: final value) when value is Map && value['menuId'] is num:
          return Result.ok((value['menuId'] as num).toInt());
        case Ok():
          return Result.ok(menuId);
        case Error(error: final error):
          return Result.error(error);
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  Future<Result<MenuItemModel>> _requestOne(Verb verb, Map<String, dynamic> body) async {
    try {
      final response = await DioProvider.of(ApiCore.menu).request(verb: verb, body: body);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(MenuItemModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoMenuInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoMenuInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
