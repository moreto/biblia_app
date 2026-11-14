import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/dicionario/dicionario/repository/dicionario_repository.dart';
import '../../features/dicionario/dicionario/ui/dicionario_view.dart';
import '../../features/dicionario/dicionario/ui/dicionario_viewmodel.dart';
import '../../features/dicionario/dicionario/use_case/dicionario_usecase.dart';
import '../routes.dart';

class DicionarioRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.dicionario,
      builder: (context, state) => DicionarioView(
        viewModel: DicionarioViewmodel(
          dicionarioUseCase: DicionarioUseCase(dicionarioRepository: locator<DicionarioRepository>()),
        ),
      ),
    ),
  };
}
