import 'package:go_router/go_router.dart';

import '../../features/home/repository/home_repository.dart';
import '../../features/home/ui/home_view.dart';
import '../../features/home/ui/home_viewmodel.dart';
import '../../features/home/use_case/home_usecase.dart';
import '../routes.dart';

class AccessRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        final viewModel = HomeViewmodel(homeUseCase: HomeUseCase(homeRepository: HomeRepository()));
        return HomeView(viewModel: viewModel);
      },
    ),
  };
}
