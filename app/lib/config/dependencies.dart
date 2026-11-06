import 'package:get_it/get_it.dart';

import '../features/home/repository/home_repository.dart';
import '../features/home/repository/home_repository_impl.dart';

final GetIt locator = GetIt.instance;

void configDependencies() {
  locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
}
