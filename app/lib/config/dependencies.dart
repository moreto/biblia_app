import 'package:get_it/get_it.dart';

import '../features/access/home/repository/home_repository.dart';
import '../features/access/home/repository/home_repository_impl.dart';
import '../features/access/login/repository/login_repository.dart';
import '../features/access/login/repository/login_repository_impl.dart';
import '../features/admin/configuracao/repository/configuracao_repository.dart';
import '../features/admin/configuracao/repository/configuracao_repository_impl.dart';
import '../features/admin/log/repository/log_repository.dart';
import '../features/admin/log/repository/log_repository_impl.dart';
import '../features/admin/menu/repository/menu_repository.dart';
import '../features/admin/menu/repository/menu_repository_impl.dart';
import '../features/admin/notificacao/repository/notificacao_repository.dart';
import '../features/admin/notificacao/repository/notificacao_repository_impl.dart';
import '../features/dashboard/repository/dashboard_repository.dart';
import '../features/dashboard/repository/dashboard_repository_impl.dart';
import '../features/dashboard/widgets/oracao/repository/oracao_repository.dart';
import '../features/dashboard/widgets/oracao/repository/oracao_repository_impl.dart';
import '../features/dashboard/widgets/versiculo/repository/versiculo_repository.dart';
import '../features/dashboard/widgets/versiculo/repository/versiculo_repository_impl.dart';

final GetIt locator = GetIt.instance;

void configDependencies() {
  locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
  locator.registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl());
  locator.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl());
  locator.registerLazySingleton<NotificacaoRepository>(() => NotificacaoRepositoryImpl());
  locator.registerLazySingleton<LogRepository>(() => LogRepositoryImpl());
  locator.registerLazySingleton<ConfiguracaoRepository>(() => ConfiguracaoRepositoryImpl());
  locator.registerLazySingleton<MenuRepository>(() => MenuRepositoryImpl());
  locator.registerLazySingleton<OracaoRepository>(() => OracaoRepositoryImpl());
  locator.registerLazySingleton<VersiculoRepository>(() => VersiculoRepositoryImpl());
}
