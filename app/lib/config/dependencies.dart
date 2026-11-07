import 'package:get_it/get_it.dart';

import '../features/access/home/repository/home_repository.dart';
import '../features/access/home/repository/home_repository_impl.dart';
import '../features/access/login/repository/login_repository.dart';
import '../features/access/login/repository/login_repository_impl.dart';
import '../features/configuracao/repository/configuracao_repository.dart';
import '../features/configuracao/repository/configuracao_repository_impl.dart';
import '../features/dashboard/repository/dashboard_repository.dart';
import '../features/dashboard/repository/dashboard_repository_impl.dart';
import '../features/log/repository/log_repository.dart';
import '../features/log/repository/log_repository_impl.dart';
import '../features/notificacao/repository/notificacao_repository.dart';
import '../features/notificacao/repository/notificacao_repository_impl.dart';

final GetIt locator = GetIt.instance;

void configDependencies() {
  locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
  locator.registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl());
  locator.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl());
  locator.registerLazySingleton<NotificacaoRepository>(() => NotificacaoRepositoryImpl());
  locator.registerLazySingleton<LogRepository>(() => LogRepositoryImpl());
  locator.registerLazySingleton<ConfiguracaoRepository>(() => ConfiguracaoRepositoryImpl());
}
