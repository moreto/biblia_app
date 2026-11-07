import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/notificacao/repository/notificacao_repository.dart';
import '../../features/notificacao/ui/notificacao_view.dart';
import '../../features/notificacao/ui/notificacao_viewmodel.dart';
import '../../features/notificacao/use_case/notificacao_usecase.dart';
import '../routes.dart';

class NotificacaoRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.notificacao,
      builder: (context, state) {
        final viewModel = NotificacaoViewmodel(
          notificacaoUseCase: NotificacaoUseCase(notificacaoRepository: locator<NotificacaoRepository>()),
        );
        return NotificacaoView(viewModel: viewModel);
      },
    ),
  };
}
