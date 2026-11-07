import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/log/repository/log_repository.dart';
import '../../features/log/ui/log_view.dart';
import '../../features/log/ui/log_viewmodel.dart';
import '../../features/log/use_case/log_usecase.dart';
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
