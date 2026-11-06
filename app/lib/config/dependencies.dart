import 'package:get_it/get_it.dart';

import '../features/access/home/repository/home_repository.dart';
import '../features/access/home/repository/home_repository_impl.dart';
import '../features/access/login/repository/login_repository.dart';
import '../features/access/login/repository/login_repository_impl.dart';
import '../features/dashboard/repository/dashboard_repository.dart';
import '../features/dashboard/repository/dashboard_repository_impl.dart';

final GetIt locator = GetIt.instance;

void configDependencies() {
  locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
  locator.registerLazySingleton<LoginRepository>(() => LoginRepositoryImpl());
  locator.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl());
}
