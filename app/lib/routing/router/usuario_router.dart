import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/access/configuracao_app/repository/configuracao_app_repository.dart';
import '../../features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import '../../features/usuario/repository/usuario_repository.dart';
import '../../features/usuario/ui/usuario_view.dart';
import '../../features/usuario/ui/usuario_viewmodel.dart';
import '../../features/usuario/use_case/usuario_usecase.dart';
import '../routes.dart';

class UsuarioRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.usuario,
      builder: (context, state) => UsuarioView(
        viewModel: UsuarioViewmodel(
          usuarioUseCase: UsuarioUseCase(
            usuarioRepository: locator<UsuarioRepository>(),
            configuracaoAppUseCase: ConfiguracaoAppUseCase(
              configuracaoAppRepository: locator<ConfiguracaoAppRepository>(),
            ),
          ),
        ),
      ),
    ),
  };
}
