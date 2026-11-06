import 'package:provider/provider.dart';

import 'app_config.dart';

List<ChangeNotifierProvider<dynamic>> configProviders() => [
  ChangeNotifierProvider<AppConfig>(create: (_) => AppConfig()),
];
