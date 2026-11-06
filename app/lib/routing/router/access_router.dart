import 'package:go_router/go_router.dart';

import '../../features/home/repository/home_repository_impl.dart';
import '../../features/home/ui/home_view.dart';
import '../../features/home/ui/home_viewmodel.dart';
import '../../features/home/use_case/home_usecase.dart';
import '../routes.dart';

abstract final class AccessRouter {
  static List<GoRoute> get routes => [
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final viewModel = HomeViewmodel(homeUseCase: HomeUseCase(homeRepository: HomeRepositoryImpl()));
        return HomeView(viewModel: viewModel);
      },
    ),
  ];
}
