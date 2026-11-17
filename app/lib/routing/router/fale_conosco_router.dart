import 'package:commons/commons.dart';
import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/fale_conosco_atendimento/repository/fale_conosco_atendimento_repository.dart';
import '../../features/fale_conosco_atendimento/ui/fale_conosco_atendimento_view.dart';
import '../../features/fale_conosco_atendimento/ui/fale_conosco_atendimento_viewmodel.dart';
import '../../features/fale_conosco_atendimento/use_case/fale_conosco_atendimento_usecase.dart';
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
          faleConoscoUseCase: FaleConoscoUseCase(faleConoscoRepository: locator<FaleConoscoRepository>()),
        ),
      ),
    ),
    GoRoute(
      path: Routes.faleConoscoAtendimento,
      builder: (context, state) => FaleConoscoAtendimentoView(
        viewModel: FaleConoscoAtendimentoViewmodel(
          faleConoscoAtendimentoUseCase: FaleConoscoAtendimentoUseCase(
            faleConoscoAtendimentoRepository: locator<FaleConoscoAtendimentoRepository>(),
            usuarioId: () => AuthSession.instance.userId,
          ),
        ),
      ),
    ),
  };
}
