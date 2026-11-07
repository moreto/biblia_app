import 'package:app/features/loggof/ui/loggof_view.dart';
import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/dashboard/repository/dashboard_repository.dart';
import '../../features/dashboard/ui/dashboard_view.dart';
import '../../features/dashboard/ui/dashboard_viewmodel.dart';
import '../../features/dashboard/use_case/dashboard_usecase.dart';
import '../../features/loggof/ui/loggof_viewmodel.dart';
import '../routes.dart';

abstract final class CommonRouter {
  static List<GoRoute> get routes => [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) {
        final viewModel = DashboardViewmodel(
          dashboardUseCase: DashboardUseCase(dashboardRepository: locator<DashboardRepository>()),
        );
        return DashboardView(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: Routes.loggof,
      builder: (context, state) {
        final viewModel = LoggofViewmodel();
        return LoggofView(viewModel: viewModel);
      },
    ),
  ];
}
