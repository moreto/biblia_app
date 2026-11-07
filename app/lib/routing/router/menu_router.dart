import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/menu/repository/menu_repository.dart';
import '../../features/menu/ui/menu_view.dart';
import '../../features/menu/ui/menu_viewmodel.dart';
import '../../features/menu/use_case/menu_usecase.dart';
import '../routes.dart';

class MenuRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.menu,
      builder: (context, state) {
        final viewModel = MenuViewmodel(menuUseCase: MenuUseCase(menuRepository: locator<MenuRepository>()));
        return MenuView(viewModel: viewModel);
      },
    ),
  };
}
