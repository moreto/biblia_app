import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/access/loggof/ui/loggof_view.dart';
import '../../features/access/loggof/ui/loggof_viewmodel.dart';
import '../../features/dashboard/repository/dashboard_repository.dart';
import '../../features/dashboard/ui/dashboard_view.dart';
import '../../features/dashboard/ui/dashboard_viewmodel.dart';
import '../../features/dashboard/use_case/dashboard_usecase.dart';
import '../../features/dashboard/widgets/musica/repository/musica_repository.dart';
import '../../features/dashboard/widgets/musica/ui/musica_viewmodel.dart';
import '../../features/dashboard/widgets/musica/use_case/musica_usecase.dart';
import '../../features/dashboard/widgets/oracao/repository/oracao_repository.dart';
import '../../features/dashboard/widgets/oracao/ui/oracao_viewmodel.dart';
import '../../features/dashboard/widgets/oracao/use_case/oracao_usecase.dart';
import '../../features/dashboard/widgets/versiculo/repository/versiculo_repository.dart';
import '../../features/dashboard/widgets/versiculo/ui/versiculo_viewmodel.dart';
import '../../features/dashboard/widgets/versiculo/use_case/versiculo_usecase.dart';
import '../../features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import '../../features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
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
        final versiculoViewModel = VersiculoViewmodel(
          versiculoUseCase: VersiculoUseCase(versiculoRepository: locator<VersiculoRepository>()),
          versiculoReacaoUseCase: VersiculoReacaoUseCase(
            versiculoReacaoRepository: locator<VersiculoReacaoRepository>(),
          ),
        );
        final musicaViewModel = MusicaViewmodel(
          musicaUseCase: MusicaUseCase(musicaRepository: locator<MusicaRepository>()),
        );
        return DashboardView(
          viewModel: viewModel,
          oracaoViewModel: oracaoViewModel,
          versiculoViewModel: versiculoViewModel,
          musicaViewModel: musicaViewModel,
        );
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
