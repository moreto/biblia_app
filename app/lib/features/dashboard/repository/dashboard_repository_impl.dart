import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/menu/menu_model.dart';
import 'dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<Result<MenuModel>> menu() async {
    try {
      final response = await DioProvider.of(ApiCore.menu).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(MenuModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'erroApi'));
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// Lê `{ "total": n }`; `total` ausente ou que não seja número vira `respostaApiInvalida`.
  @override
  Future<Result<int>> mensagensNaoLidas() async {
    try {
      final response = await DioProvider.of(ApiCore.mensagemNaoLidas).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is Map && value['total'] is num:
          return Result.ok((value['total'] as num).toInt());
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
