import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/comunidade/repository/comunidade_repository.dart';
import '../../features/comunidade/ui/comunidade_view.dart';
import '../../features/comunidade/ui/comunidade_viewmodel.dart';
import '../../features/comunidade/use_case/comunidade_usecase.dart';
import '../routes.dart';

class ComunidadeRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.comunidade,
      builder: (context, state) {
        final viewModel = ComunidadeViewmodel(
          comunidadeUseCase: ComunidadeUseCase(comunidadeRepository: locator<ComunidadeRepository>()),
        );
        return ComunidadeView(viewModel: viewModel);
      },
    ),
  };
}
