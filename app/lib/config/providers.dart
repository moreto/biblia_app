import 'package:provider/provider.dart';

import 'app_config.dart';
import 'dependencies.dart';

List<ChangeNotifierProvider<dynamic>> configProviders() => [
  // Instância única, já carregada em `main` antes do `runApp`.
  ChangeNotifierProvider<AppConfig>.value(value: locator<AppConfig>()),
];
