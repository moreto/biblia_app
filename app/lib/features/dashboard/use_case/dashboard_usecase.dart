import 'package:commons/commons.dart';

import '../../../data/model/menu/menu_model.dart';
import '../repository/dashboard_repository.dart';

class DashboardUseCase {
  DashboardUseCase({required this.dashboardRepository}) {
    Log.print(super.runtimeType);
  }

  final DashboardRepository dashboardRepository;

  Future<Result<MenuModel>> menu() async {
    final result = await dashboardRepository.menu();
    switch (result) {
      case Ok<MenuModel>():
        return Result.ok(result.value);
      case Error<MenuModel>():
        return Result.error(result.error);
    }
  }
}
