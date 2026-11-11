import 'package:go_router/go_router.dart';

import '../../config/dependencies.dart';
import '../../features/comunidade/comunidade/repository/comunidade_repository.dart';
import '../../features/comunidade/comunidade/ui/comunidade_view.dart';
import '../../features/comunidade/comunidade/ui/comunidade_viewmodel.dart';
import '../../features/comunidade/comunidade/use_case/comunidade_usecase.dart';
import '../../features/comunidade/comunidade_contato/repository/comunidade_contato_repository.dart';
import '../../features/comunidade/comunidade_contato/ui/comunidade_contato_viewmodel.dart';
import '../../features/comunidade/comunidade_contato/use_case/comunidade_contato_usecase.dart';
import '../../features/comunidade/comunidade_lista/repository/comunidade_lista_repository.dart';
import '../../features/comunidade/comunidade_lista/ui/comunidade_lista_view.dart';
import '../../features/comunidade/comunidade_lista/ui/comunidade_lista_viewmodel.dart';
import '../../features/comunidade/comunidade_lista/use_case/comunidade_lista_usecase.dart';
import '../../features/comunidade/comunidade_usuario/repository/comunidade_usuario_repository.dart';
import '../../features/comunidade/comunidade_usuario/ui/comunidade_usuario_view.dart';
import '../../features/comunidade/comunidade_usuario/ui/comunidade_usuario_viewmodel.dart';
import '../../features/comunidade/comunidade_usuario/use_case/comunidade_usuario_usecase.dart';
import '../../features/comunidade/comunidade_endereco/repository/comunidade_endereco_repository.dart';
import '../../features/comunidade/comunidade_endereco/ui/comunidade_endereco_viewmodel.dart';
import '../../features/comunidade/comunidade_endereco/use_case/comunidade_endereco_usecase.dart';
import '../routes.dart';

class ComunidadeRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.comunidade,
      builder: (context, state) {
        final comunidadeUseCase = ComunidadeUseCase(comunidadeRepository: locator<ComunidadeRepository>());
        final viewModel = ComunidadeViewmodel(comunidadeUseCase: comunidadeUseCase);
        final enderecoViewModel = ComunidadeEnderecoViewmodel(
          comunidadeEnderecoUseCase: ComunidadeEnderecoUseCase(
            comunidadeEnderecoRepository: locator<ComunidadeEnderecoRepository>(),
            comunidadeUseCase: comunidadeUseCase,
          ),
        );
        final contatoViewModel = ComunidadeContatoViewmodel(
          comunidadeContatoUseCase: ComunidadeContatoUseCase(
            comunidadeContatoRepository: locator<ComunidadeContatoRepository>(),
            comunidadeUseCase: comunidadeUseCase,
          ),
        );
        return ComunidadeView(
          viewModel: viewModel,
          enderecoViewModel: enderecoViewModel,
          contatoViewModel: contatoViewModel,
        );
      },
    ),
    GoRoute(
      path: Routes.comunidadeUsuario,
      builder: (context, state) {
        final viewModel = ComunidadeUsuarioViewmodel(
          comunidadeUsuarioUseCase: ComunidadeUsuarioUseCase(
            comunidadeUsuarioRepository: locator<ComunidadeUsuarioRepository>(),
            comunidadeUseCase: ComunidadeUseCase(comunidadeRepository: locator<ComunidadeRepository>()),
          ),
        );
        return ComunidadeUsuarioView(
          viewModel: viewModel,
          comuId: int.tryParse(state.uri.queryParameters['comuId'] ?? ''),
        );
      },
    ),
    GoRoute(
      path: Routes.comunidadeLista,
      builder: (context, state) => ComunidadeListaView(
        viewModel: ComunidadeListaViewmodel(
          comunidadeListaUseCase: ComunidadeListaUseCase(
            comunidadeListaRepository: locator<ComunidadeListaRepository>(),
          ),
        ),
      ),
    ),
  };
}
