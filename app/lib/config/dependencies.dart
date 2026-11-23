import 'package:get_it/get_it.dart';

import '../data/local/banco_local.dart';
import '../data/local/conectividade.dart';
import '../data/local/leitura_local_store.dart';
import '../features/biblia/biblia_leitura/offline/biblia_leitura_repository_offline.dart';
import '../features/biblia/biblia_leitura/offline/leitura_offline_repository.dart';
import '../features/biblia/biblia_leitura/offline/leitura_sincronizacao.dart';
import '../features/biblia/biblia_leitura/offline/versiculo_indicacao_repository_offline.dart';
import '../features/biblia/biblia_leitura/offline/versiculo_reacao_repository_offline.dart';

import '../features/access/configuracao_app/repository/configuracao_app_repository.dart';
import '../features/access/configuracao_app/repository/configuracao_app_repository_impl.dart';
import '../features/access/home/repository/home_repository.dart';
import '../features/access/home/repository/home_repository_impl.dart';
import '../features/access/home/widgets/funcionalidade/repository/funcionalidade_repository.dart';
import '../features/access/home/widgets/funcionalidade/repository/funcionalidade_repository_impl.dart';
import '../features/access/login/repository/login_repository.dart';
import '../features/access/login/repository/login_repository_impl.dart';
import '../features/access/registro/repository/registro_repository.dart';
import '../features/access/registro/repository/registro_repository_impl.dart';
import '../features/admin/configuracao/repository/configuracao_repository.dart';
import '../features/admin/configuracao/repository/configuracao_repository_impl.dart';
import '../features/admin/log/repository/log_repository.dart';
import '../features/admin/log/repository/log_repository_impl.dart';
import '../features/admin/menu/repository/menu_repository.dart';
import '../features/admin/menu/repository/menu_repository_impl.dart';
import '../features/admin/notificacao/repository/notificacao_repository.dart';
import '../features/admin/notificacao/repository/notificacao_repository_impl.dart';
import '../features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import '../features/biblia/biblia_leitura/repository/biblia_leitura_repository_impl.dart';
import '../features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import '../features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_repository_impl.dart';
import '../features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_usuario_repository.dart';
import '../features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_usuario_repository_impl.dart';
import '../features/biblia/renomado/repository/renomado_repository.dart';
import '../features/biblia/renomado/repository/renomado_repository_impl.dart';
import '../features/biblia/versiculo_indicado/repository/versiculo_indicado_repository.dart';
import '../features/biblia/versiculo_indicado/repository/versiculo_indicado_repository_impl.dart';
import '../features/biblia/versiculo_renomado/repository/versiculo_renomado_repository.dart';
import '../features/biblia/versiculo_renomado/repository/versiculo_renomado_repository_impl.dart';
import '../features/comunidade/comunidade/repository/comunidade_repository.dart';
import '../features/comunidade/comunidade/repository/comunidade_repository_impl.dart';
import '../features/comunidade/comunidade_contato/repository/comunidade_contato_repository.dart';
import '../features/comunidade/comunidade_contato/repository/comunidade_contato_repository_impl.dart';
import '../features/comunidade/comunidade_endereco/repository/comunidade_endereco_repository.dart';
import '../features/comunidade/comunidade_lista/repository/comunidade_lista_repository.dart';
import '../features/comunidade/comunidade_lista/repository/comunidade_lista_repository_impl.dart';
import '../features/comunidade/comunidade_usuario/repository/comunidade_usuario_repository.dart';
import '../features/comunidade/comunidade_usuario/repository/comunidade_usuario_repository_impl.dart';
import '../features/comunidade/comunidade_endereco/repository/comunidade_endereco_repository_impl.dart';
import '../features/dashboard/repository/dashboard_repository.dart';
import '../features/dicionario/repository/dicionario_repository.dart';
import '../features/dicionario/repository/dicionario_repository_impl.dart';
import '../features/fale_conosco/repository/fale_conosco_repository.dart';
import '../features/fale_conosco/repository/fale_conosco_repository_impl.dart';
import '../features/fale_conosco_atendimento/repository/fale_conosco_atendimento_repository.dart';
import '../features/fale_conosco_atendimento/repository/fale_conosco_atendimento_repository_impl.dart';
import '../features/grupo_leitura/grupo_leitura/repository/grupo_leitura_repository.dart';
import '../features/grupo_leitura/grupo_leitura/repository/grupo_leitura_repository_impl.dart';
import '../features/grupo_leitura/grupo_leitura_agenda/repository/grupo_leitura_agenda_repository.dart';
import '../features/grupo_leitura/grupo_leitura_agenda/repository/grupo_leitura_agenda_repository_impl.dart';
import '../features/grupo_leitura/grupo_leitura_atividade/repository/grupo_leitura_atividade_repository.dart';
import '../features/grupo_leitura/grupo_leitura_atividade/repository/grupo_leitura_atividade_repository_impl.dart';
import '../features/grupo_leitura/grupo_leitura_participante/repository/grupo_leitura_participante_repository.dart';
import '../features/grupo_leitura/grupo_leitura_participante/repository/grupo_leitura_participante_repository_impl.dart';
import '../features/historico_leitura/repository/historico_leitura_repository.dart';
import '../features/historico_leitura/repository/historico_leitura_repository_impl.dart';
import '../features/lgpd/usuario_consentimento/repository/usuario_consentimento_repository.dart';
import '../features/lgpd/usuario_consentimento/repository/usuario_consentimento_repository_impl.dart';
import '../features/mensagem/mensagem_envio/repository/mensagem_envio_repository.dart';
import '../features/mensagem/mensagem_envio/repository/mensagem_envio_repository_impl.dart';
import '../features/mensagem/mensagem_lista/repository/mensagem_lista_repository.dart';
import '../features/mensagem/mensagem_lista/repository/mensagem_lista_repository_impl.dart';
import '../features/dashboard/repository/dashboard_repository_impl.dart';
import '../features/usuario/repository/usuario_repository.dart';
import '../features/usuario/repository/usuario_repository_impl.dart';
import '../features/dashboard/widgets/musica/repository/musica_repository.dart';
import '../features/dashboard/widgets/musica/repository/musica_repository_impl.dart';
import '../features/dashboard/widgets/oracao/repository/oracao_repository.dart';
import '../features/dashboard/widgets/oracao/repository/oracao_repository_impl.dart';
import '../features/dashboard/widgets/versiculo/repository/versiculo_repository.dart';
import '../features/dashboard/widgets/versiculo/repository/versiculo_repository_impl.dart';
import '../features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import '../features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository_impl.dart';
import 'app_config.dart';

final GetIt locator = GetIt.instance;

void configDependencies() {
  locator.registerLazySingleton<AppConfig>(() => AppConfig());
  locator.registerLazySingleton<ConfiguracaoAppRepository>(() => ConfiguracaoAppRepositoryImpl());
  locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
  locator.registerLazySingleton<FuncionalidadeRepository>(() => FuncionalidadeRepositoryImpl());
  locator.registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl());
  locator.registerLazySingleton<RegistroRepository>(() => RegistroRepositoryImpl());
  locator.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl());
  locator.registerLazySingleton<NotificacaoRepository>(() => NotificacaoRepositoryImpl());
  locator.registerLazySingleton<LogRepository>(() => LogRepositoryImpl());
  locator.registerLazySingleton<ConfiguracaoRepository>(() => ConfiguracaoRepositoryImpl());
  locator.registerLazySingleton<MenuRepository>(() => MenuRepositoryImpl());
  locator.registerLazySingleton<OracaoRepository>(() => OracaoRepositoryImpl());
  locator.registerLazySingleton<MusicaRepository>(() => MusicaRepositoryImpl());
  locator.registerLazySingleton<VersiculoRepository>(() => VersiculoRepositoryImpl());
  _configLeituraOffline();
  locator.registerLazySingleton<VersiculoIndicacaoUsuarioRepository>(() => VersiculoIndicacaoUsuarioRepositoryImpl());
  locator.registerLazySingleton<RenomadoRepository>(() => RenomadoRepositoryImpl());
  locator.registerLazySingleton<VersiculoRenomadoRepository>(() => VersiculoRenomadoRepositoryImpl());
  locator.registerLazySingleton<ComunidadeRepository>(() => ComunidadeRepositoryImpl());
  locator.registerLazySingleton<ComunidadeEnderecoRepository>(() => ComunidadeEnderecoRepositoryImpl());
  locator.registerLazySingleton<ComunidadeContatoRepository>(() => ComunidadeContatoRepositoryImpl());
  locator.registerLazySingleton<ComunidadeUsuarioRepository>(() => ComunidadeUsuarioRepositoryImpl());
  locator.registerLazySingleton<ComunidadeListaRepository>(() => ComunidadeListaRepositoryImpl());
  locator.registerLazySingleton<VersiculoIndicadoRepository>(() => VersiculoIndicadoRepositoryImpl());
  locator.registerLazySingleton<MensagemListaRepository>(() => MensagemListaRepositoryImpl());
  locator.registerLazySingleton<MensagemEnvioRepository>(() => MensagemEnvioRepositoryImpl());
  locator.registerLazySingleton<DicionarioRepository>(() => DicionarioRepositoryImpl());
  locator.registerLazySingleton<UsuarioConsentimentoRepository>(() => UsuarioConsentimentoRepositoryImpl());
  locator.registerLazySingleton<FaleConoscoRepository>(() => FaleConoscoRepositoryImpl());
  locator.registerLazySingleton<FaleConoscoAtendimentoRepository>(() => FaleConoscoAtendimentoRepositoryImpl());
  locator.registerLazySingleton<UsuarioRepository>(() => UsuarioRepositoryImpl());
  locator.registerLazySingleton<GrupoLeituraRepository>(() => GrupoLeituraRepositoryImpl());
  locator.registerLazySingleton<GrupoLeituraParticipanteRepository>(() => GrupoLeituraParticipanteRepositoryImpl());
  locator.registerLazySingleton<GrupoLeituraAgendaRepository>(() => GrupoLeituraAgendaRepositoryImpl());
  locator.registerLazySingleton<GrupoLeituraAtividadeRepository>(() => GrupoLeituraAtividadeRepositoryImpl());
  // Usa o repository da leitura registrado em _configLeituraOffline, para funcionar também sem conexão.
  locator.registerLazySingleton<HistoricoLeituraRepository>(
    () => HistoricoLeituraRepositoryImpl(leitura: locator<BibliaLeituraRepository>()),
  );
}

/// Leitura da Bíblia sem conexão: banco local, conexão, sincronização e os repositories da leitura, que decoram os
/// da API (veja `files/docs/arquitetura.md`, seção "Leitura offline"). A sincronização recebe os repositories da
/// API diretamente, para não gravar de novo no aparelho.
void _configLeituraOffline() {
  locator.registerLazySingleton<BancoLocal>(() => BancoLocal());
  locator.registerLazySingleton<LeituraLocalStore>(() => LeituraLocalStore(locator<BancoLocal>()));
  locator.registerLazySingleton<Conectividade>(() => ConectividadePlus());
  locator.registerLazySingleton<LeituraSincronizacao>(
    () => LeituraSincronizacao(
      store: locator<LeituraLocalStore>(),
      conectividade: locator<Conectividade>(),
      bibliaRemoto: BibliaLeituraRepositoryImpl(),
      reacaoRemoto: VersiculoReacaoRepositoryImpl(),
      indicacaoRemoto: VersiculoIndicacaoRepositoryImpl(),
    ),
  );
  locator.registerLazySingleton<BibliaLeituraRepository>(
    () => BibliaLeituraRepositoryOffline(
      api: BibliaLeituraRepositoryImpl(),
      store: locator<LeituraLocalStore>(),
      conectividade: locator<Conectividade>(),
      sincronizacao: locator<LeituraSincronizacao>(),
    ),
  );
  locator.registerLazySingleton<VersiculoReacaoRepository>(
    () => VersiculoReacaoRepositoryOffline(
      api: VersiculoReacaoRepositoryImpl(),
      store: locator<LeituraLocalStore>(),
      conectividade: locator<Conectividade>(),
      sincronizacao: locator<LeituraSincronizacao>(),
    ),
  );
  locator.registerLazySingleton<VersiculoIndicacaoRepository>(
    () => VersiculoIndicacaoRepositoryOffline(
      api: VersiculoIndicacaoRepositoryImpl(),
      store: locator<LeituraLocalStore>(),
      conectividade: locator<Conectividade>(),
      sincronizacao: locator<LeituraSincronizacao>(),
    ),
  );
  locator.registerLazySingleton<LeituraOfflineRepository>(
    () => LeituraOfflineRepositoryImpl(store: locator<LeituraLocalStore>(), conectividade: locator<Conectividade>()),
  );
}
