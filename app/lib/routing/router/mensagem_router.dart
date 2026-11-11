import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/mensagem/mensagem_envio/repository/mensagem_envio_repository.dart';
import '../../features/mensagem/mensagem_envio/ui/mensagem_envio_viewmodel.dart';
import '../../features/mensagem/mensagem_envio/use_case/mensagem_envio_usecase.dart';
import '../../features/mensagem/mensagem_lista/repository/mensagem_lista_repository.dart';
import '../../features/mensagem/mensagem_lista/ui/mensagem_lista_view.dart';
import '../../features/mensagem/mensagem_lista/ui/mensagem_lista_viewmodel.dart';
import '../../features/mensagem/mensagem_lista/use_case/mensagem_lista_usecase.dart';
import '../routes.dart';

class MensagemRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.mensagemLista,
      builder: (context, state) => MensagemListaView(
        viewModel: MensagemListaViewmodel(
          mensagemListaUseCase: MensagemListaUseCase(mensagemListaRepository: locator<MensagemListaRepository>()),
        ),
        envioViewModel: MensagemEnvioViewmodel(
          mensagemEnvioUseCase: MensagemEnvioUseCase(mensagemEnvioRepository: locator<MensagemEnvioRepository>()),
        ),
      ),
    ),
  };
}
