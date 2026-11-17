import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/lgpd/usuario_consentimento/repository/usuario_consentimento_repository.dart';
import '../../features/lgpd/usuario_consentimento/ui/usuario_consentimento_view.dart';
import '../../features/lgpd/usuario_consentimento/ui/usuario_consentimento_viewmodel.dart';
import '../../features/lgpd/usuario_consentimento/use_case/usuario_consentimento_usecase.dart';
import '../routes.dart';

class LgpdRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.usuarioConsentimento,
      builder: (context, state) => UsuarioConsentimentoView(
        viewModel: UsuarioConsentimentoViewmodel(
          usuarioConsentimentoUseCase: UsuarioConsentimentoUseCase(
            usuarioConsentimentoRepository: locator<UsuarioConsentimentoRepository>(),
          ),
        ),
      ),
    ),
  };
}
