import 'package:app/app.dart';
import 'package:app/config/app_config.dart';
import 'package:app/config/dependencies.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DeviceInfo.instance.initialize();
  configDependencies();
  // Aplica o tema e o idioma escolhidos pelo usuário já na abertura do app.
  await locator<AppConfig>().load();
  runApp(const MyApp());
}
