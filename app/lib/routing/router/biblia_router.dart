import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_view.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usuario_usecase.dart';
import 'package:go_router/go_router.dart';

import '../../config/anotacao_leitura.dart';
import '../../config/app_config.dart';
import '../../config/brilho_tela.dart';
import '../../config/compartilhamento.dart';
import '../../config/marca_texto.dart';
import '../../config/narracao_voz.dart';
import '../../config/orientacao_tela.dart';
import '../../features/biblia/configuracao_leitura/ui/configuracao_leitura_view.dart';
import '../../features/biblia/configuracao_leitura/ui/configuracao_leitura_viewmodel.dart';
import '../../features/biblia/configuracao_leitura/ui/versao_biblia_view.dart';
import '../../features/biblia/configuracao_leitura/ui/voz_narracao_view.dart';
import '../../features/biblia/configuracao_leitura/use_case/configuracao_leitura_usecase.dart';
import '../../config/dependencies.dart';
import '../../features/dicionario/repository/dicionario_repository.dart';
import '../../features/dicionario/use_case/dicionario_usecase.dart';
import '../../features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import '../../features/biblia/biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import '../../features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../../features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import '../../features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_usuario_repository.dart';
import '../../data/model/biblia/renomado_model.dart';
import '../../features/biblia/renomado/repository/renomado_repository.dart';
import '../../features/biblia/renomado/ui/renomado_view.dart';
import '../../features/biblia/renomado/ui/renomado_viewmodel.dart';
import '../../features/biblia/renomado/use_case/renomado_usecase.dart';
import '../../features/biblia/versiculo_indicado/repository/versiculo_indicado_repository.dart';
import '../../features/biblia/versiculo_indicado/ui/versiculo_indicado_view.dart';
import '../../features/biblia/versiculo_indicado/ui/versiculo_indicado_viewmodel.dart';
import '../../features/biblia/versiculo_indicado/use_case/versiculo_indicado_usecase.dart';
import '../../features/biblia/versiculo_renomado/repository/versiculo_renomado_repository.dart';
import '../../features/biblia/versiculo_renomado/ui/versiculo_renomado_view.dart';
import '../../features/biblia/versiculo_renomado/ui/versiculo_renomado_viewmodel.dart';
import '../../features/biblia/versiculo_renomado/use_case/versiculo_renomado_usecase.dart';
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
            ultimoCapituloPreferencia: locator<AppConfig>(),
            leituraPreferencia: locator<AppConfig>(),
            brilhoTela: const BrilhoTelaAparelho(),
            dicionarioUseCase: DicionarioUseCase(dicionarioRepository: locator<DicionarioRepository>()),
            narracaoVoz: NarracaoVozAparelho(),
            marcaTextoArmazenamento: MarcaTextoArmazenamentoLocal(),
            anotacaoArmazenamento: AnotacaoArmazenamentoLocal(),
            compartilhamento: const CompartilhamentoSistema(),
            orientacaoTela: const OrientacaoTelaSistema(),
          ),
          versiculoIndicacaoUseCase: VersiculoIndicacaoUseCase(
            versiculoIndicacaoRepository: locator<VersiculoIndicacaoRepository>(),
          ),
          versiculoReacaoUseCase: VersiculoReacaoUseCase(
            versiculoReacaoRepository: locator<VersiculoReacaoRepository>(),
          ),
          versiculoIndicacaoUsuarioUseCase: VersiculoIndicacaoUsuarioUseCase(
            versiculoIndicacaoUsuarioRepository: locator<VersiculoIndicacaoUsuarioRepository>(),
          ),
          // Abertura direta num versículo (ex.: a partir dos versículos de um renomado).
          destino: LeituraDestino.fromQuery(state.uri.queryParameters),
        );
        return BibliaLeituraView(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: Routes.configuracoesLeitura,
      // Abre por cima da leitura, com o viewmodel dela no `extra`; sem ele (link direto), vai para a leitura.
      redirect: (context, state) => state.extra is BibliaLeituraViewmodel ? null : Routes.bibliaLeitura,
      builder: (context, state) => ConfiguracaoLeituraView(
        leitura: state.extra! as BibliaLeituraViewmodel,
        viewModel: ConfiguracaoLeituraViewmodel(
          configuracaoLeituraUseCase: ConfiguracaoLeituraUseCase(
            leituraPreferencia: locator<AppConfig>(),
            orientacaoTela: const OrientacaoTelaSistema(),
          ),
        ),
      ),
    ),
    GoRoute(
      path: Routes.versaoBiblia,
      redirect: (context, state) => state.extra is BibliaLeituraViewmodel ? null : Routes.bibliaLeitura,
      builder: (context, state) => VersaoBibliaView(leitura: state.extra! as BibliaLeituraViewmodel),
    ),
    GoRoute(
      path: Routes.vozNarracao,
      redirect: (context, state) => state.extra is BibliaLeituraViewmodel ? null : Routes.bibliaLeitura,
      builder: (context, state) => VozNarracaoView(leitura: state.extra! as BibliaLeituraViewmodel),
    ),
    GoRoute(
      path: Routes.renomado,
      builder: (context, state) {
        final viewModel = RenomadoViewmodel(
          renomadoUseCase: RenomadoUseCase(renomadoRepository: locator<RenomadoRepository>()),
        );
        return RenomadoView(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: '${Routes.versiculoRenomado}/:renoId',
      builder: (context, state) {
        final extra = state.extra;
        final viewModel = VersiculoRenomadoViewmodel(
          renoId: int.tryParse(state.pathParameters['renoId'] ?? '') ?? 0,
          renomado: extra is RenomadoModel ? extra : null,
          versiculoRenomadoUseCase: VersiculoRenomadoUseCase(
            versiculoRenomadoRepository: locator<VersiculoRenomadoRepository>(),
            bibliaLeituraUseCase: BibliaLeituraUseCase(
              bibliaLeituraRepository: locator<BibliaLeituraRepository>(),
              versaoPreferencia: locator<AppConfig>(),
            ),
          ),
        );
        return VersiculoRenomadoView(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: Routes.versiculoIndicado,
      builder: (context, state) => VersiculoIndicadoView(
        viewModel: VersiculoIndicadoViewmodel(
          versiculoIndicadoUseCase: VersiculoIndicadoUseCase(
            versiculoIndicadoRepository: locator<VersiculoIndicadoRepository>(),
          ),
        ),
      ),
    ),
  };
}
