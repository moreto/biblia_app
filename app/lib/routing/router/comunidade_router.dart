import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/comunidade/comunidade_endereco/repository/comunidade_endereco_repository.dart';
import '../../features/comunidade/comunidade_endereco/ui/comunidade_endereco_viewmodel.dart';
import '../../features/comunidade/comunidade_endereco/use_case/comunidade_endereco_usecase.dart';
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
        final comunidadeUseCase = ComunidadeUseCase(comunidadeRepository: locator<ComunidadeRepository>());
        final viewModel = ComunidadeViewmodel(comunidadeUseCase: comunidadeUseCase);
        final enderecoViewModel = ComunidadeEnderecoViewmodel(
          comunidadeEnderecoUseCase: ComunidadeEnderecoUseCase(
            comunidadeEnderecoRepository: locator<ComunidadeEnderecoRepository>(),
            comunidadeUseCase: comunidadeUseCase,
          ),
        );
        return ComunidadeView(viewModel: viewModel, enderecoViewModel: enderecoViewModel);
      },
    ),
  };
}
