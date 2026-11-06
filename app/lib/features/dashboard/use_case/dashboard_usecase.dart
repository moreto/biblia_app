import 'package:commons/commons.dart';

import '../../../data/model/healt_model.dart';
import '../repository/dashboard_repository.dart';

class DashboardUseCase {
  DashboardUseCase({required this.dashboardRepository});

  final DashboardRepository dashboardRepository;

  Future<Result<HealtModel>> healt() async {
    final result = await dashboardRepository.healt();
    switch (result) {
      case Ok<HealtModel>():
        return Result.ok(result.value);
      case Error<HealtModel>():
        return Result.error(result.error);
    }
  }
}
