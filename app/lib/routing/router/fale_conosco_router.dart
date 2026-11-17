import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../config/usuario_session.dart';
import '../../features/fale_conosco/repository/fale_conosco_repository.dart';
import '../../features/fale_conosco/ui/fale_conosco_view.dart';
import '../../features/fale_conosco/ui/fale_conosco_viewmodel.dart';
import '../../features/fale_conosco/use_case/fale_conosco_usecase.dart';
import '../routes.dart';

class FaleConoscoRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.faleConosco,
      builder: (context, state) => FaleConoscoView(
        viewModel: FaleConoscoViewmodel(
          faleConoscoUseCase: FaleConoscoUseCase(
            faleConoscoRepository: locator<FaleConoscoRepository>(),
            usuario: () => UsuarioSession.instance.usuarioDetalhe,
          ),
        ),
      ),
    ),
  };
}
