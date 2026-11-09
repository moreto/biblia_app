import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_view.dart';
import 'package:app/features/biblia/versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../config/dependencies.dart';
import '../../features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import '../../features/biblia/biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import '../../features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../../features/biblia/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import '../../features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import '../../features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import '../routes.dart';

class BibliaRouter {
  static Set<GoRoute> get routes => {
    GoRoute(
      path: Routes.bibliaLeitura,
      builder: (context, state) {
        final viewModel = BibliaLeituraViewmodel(
          bibliaLeituraUseCase: BibliaLeituraUseCase(
            bibliaLeituraRepository: locator<BibliaLeituraRepository>(),
            versaoPreferencia: locator<AppConfig>(),
          ),
          versiculoIndicacaoUseCase: VersiculoIndicacaoUseCase(
            versiculoIndicacaoRepository: locator<VersiculoIndicacaoRepository>(),
          ),
          versiculoReacaoUseCase: VersiculoReacaoUseCase(
            versiculoReacaoRepository: locator<VersiculoReacaoRepository>(),
          ),
        );
        return BibliaLeituraView(viewModel: viewModel);
      },
    ),
  };
}
