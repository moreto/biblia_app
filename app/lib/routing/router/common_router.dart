import 'package:app/features/loggof/ui/loggof_view.dart';
import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/dashboard/repository/dashboard_repository.dart';
import '../../features/dashboard/ui/dashboard_view.dart';
import '../../features/dashboard/ui/dashboard_viewmodel.dart';
import '../../features/dashboard/use_case/dashboard_usecase.dart';
import '../../features/loggof/ui/loggof_viewmodel.dart';
import '../../features/oracao/repository/oracao_repository.dart';
import '../../features/oracao/ui/oracao_viewmodel.dart';
import '../../features/oracao/use_case/oracao_usecase.dart';
import '../routes.dart';

abstract final class CommonRouter {
  static List<GoRoute> get routes => [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) {
        final viewModel = DashboardViewmodel(
          dashboardUseCase: DashboardUseCase(dashboardRepository: locator<DashboardRepository>()),
        );
        // Widgets da dashboard: cada card tem o próprio viewmodel.
        final oracaoViewModel = OracaoViewmodel(
          oracaoUseCase: OracaoUseCase(oracaoRepository: locator<OracaoRepository>()),
        );
        return DashboardView(viewModel: viewModel, oracaoViewModel: oracaoViewModel);
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
