import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/admin/log/repository/log_repository.dart';
import '../../features/admin/log/ui/log_view.dart';
import '../../features/admin/log/ui/log_viewmodel.dart';
import '../../features/admin/log/use_case/log_usecase.dart';
import '../routes.dart';

class LogRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.log,
      builder: (context, state) {
        final viewModel = LogViewmodel(logUseCase: LogUseCase(logRepository: locator<LogRepository>()));
        return LogView(viewModel: viewModel);
      },
    ),
  };
}
