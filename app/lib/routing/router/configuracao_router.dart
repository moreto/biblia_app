import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/admin/configuracao/repository/configuracao_repository.dart';
import '../../features/admin/configuracao/ui/configuracao_view.dart';
import '../../features/admin/configuracao/ui/configuracao_viewmodel.dart';
import '../../features/admin/configuracao/use_case/configuracao_usecase.dart';
import '../routes.dart';

class ConfiguracaoRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.configuracao,
      builder: (context, state) {
        final viewModel = ConfiguracaoViewmodel(
          configuracaoUseCase: ConfiguracaoUseCase(configuracaoRepository: locator<ConfiguracaoRepository>()),
        );
        return ConfiguracaoView(viewModel: viewModel);
      },
    ),
  };
}
