import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../config/dependencies.dart';
import '../../features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import '../../features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../../features/access/configuracao_app/repository/configuracao_app_repository.dart';
import '../../features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import '../../features/access/home/ui/home_view.dart';
import '../../features/access/home/ui/home_viewmodel.dart';
import '../../features/access/home/use_case/home_usecase.dart';
import '../../features/access/home_old/repository/home_old_repository.dart';
import '../../features/access/home_old/ui/home_old_view.dart';
import '../../features/access/home_old/ui/home_old_viewmodel.dart';
import '../../features/access/home_old/use_case/home_old_usecase.dart';
import '../../features/access/home_old/widgets/funcionalidade/repository/funcionalidade_repository.dart';
import '../../features/access/home_old/widgets/funcionalidade/ui/funcionalidade_viewmodel.dart';
import '../../features/access/home_old/widgets/funcionalidade/use_case/funcionalidade_usecase.dart';
import '../../features/access/login/repository/login_repository.dart';
import '../../features/access/login/ui/login_view.dart';
import '../../features/access/login/ui/login_viewmodel.dart';
import '../../features/access/login/use_case/login_usecase.dart';
import '../../features/access/registro/repository/registro_repository.dart';
import '../../features/access/registro/ui/registro_view.dart';
import '../../features/access/registro/ui/registro_viewmodel.dart';
import '../../features/access/registro/use_case/registro_usecase.dart';
import '../routes.dart';

abstract final class AccessRouter {
  static List<GoRoute> get routes => [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final viewModel = HomeViewmodel(
          homeUseCase: HomeUseCase(
            bibliaLeituraUseCase: BibliaLeituraUseCase(
              bibliaLeituraRepository: locator<BibliaLeituraRepository>(),
              versaoPreferencia: locator<AppConfig>(),
            ),
            ultimoCapituloPreferencia: locator<AppConfig>(),
          ),
        );
        return HomeView(viewModel: viewModel);
      },
    ),

    GoRoute(
      path: Routes.homeOld,
      builder: (context, state) {
        final viewModel = HomeOldViewmodel(
          homeOldUseCase: HomeOldUseCase(homeOldRepository: locator<HomeOldRepository>()),
        );
        // Widget da home antiga: o card de funcionalidades tem o próprio viewmodel.
        final funcionalidadeViewModel = FuncionalidadeViewmodel(
          funcionalidadeUseCase: FuncionalidadeUseCase(funcionalidadeRepository: locator<FuncionalidadeRepository>()),
        );
        return HomeOldView(viewModel: viewModel, funcionalidadeViewModel: funcionalidadeViewModel);
      },
    ),

    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        final viewModel = LoginViewmodel(
          loginUseCase: LoginUseCase(
            loginRepository: locator<LoginRepository>(),
            configuracaoAppUseCase: ConfiguracaoAppUseCase(
              configuracaoAppRepository: locator<ConfiguracaoAppRepository>(),
            ),
          ),
        );
        return LoginView(viewModel: viewModel);
      },
    ),

    GoRoute(
      path: Routes.registro,
      builder: (context, state) {
        final viewModel = RegistroViewmodel(
          registroUseCase: RegistroUseCase(
            registroRepository: locator<RegistroRepository>(),
            configuracaoAppUseCase: ConfiguracaoAppUseCase(
              configuracaoAppRepository: locator<ConfiguracaoAppRepository>(),
            ),
          ),
        );
        return RegistroView(viewModel: viewModel);
      },
    ),
  ];
}
