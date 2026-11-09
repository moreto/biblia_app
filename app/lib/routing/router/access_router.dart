import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/access/home/repository/home_repository.dart';
import '../../features/access/home/ui/home_view.dart';
import '../../features/access/home/ui/home_viewmodel.dart';
import '../../features/access/home/use_case/home_usecase.dart';
import '../../features/access/home/widgets/funcionalidade/repository/funcionalidade_repository.dart';
import '../../features/access/home/widgets/funcionalidade/ui/funcionalidade_viewmodel.dart';
import '../../features/access/home/widgets/funcionalidade/use_case/funcionalidade_usecase.dart';
import '../../features/access/login/repository/login_repository.dart';
import '../../features/access/login/ui/login_view.dart';
import '../../features/access/login/ui/login_viewmodel.dart';
import '../../features/access/login/use_case/login_usecase.dart';
import '../routes.dart';

abstract final class AccessRouter {
  static List<GoRoute> get routes => [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final viewModel = HomeViewmodel(homeUseCase: HomeUseCase(homeRepository: locator<HomeRepository>()));
        // Widget da home: o card de funcionalidades tem o próprio viewmodel.
        final funcionalidadeViewModel = FuncionalidadeViewmodel(
          funcionalidadeUseCase: FuncionalidadeUseCase(funcionalidadeRepository: locator<FuncionalidadeRepository>()),
        );
        return HomeView(viewModel: viewModel, funcionalidadeViewModel: funcionalidadeViewModel);
      },
    ),

    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        final viewModel = LoginViewmodel(loginUseCase: LoginUseCase(loginRepository: locator<LoginRepository>()));
        return LoginView(viewModel: viewModel);
      },
    ),
  ];
}
