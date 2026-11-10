import 'dart:async';

import 'package:app/app.dart';
import 'package:app/config/app_config.dart';
import 'package:app/config/dependencies.dart';
import 'package:app/features/access/configuracao_app/repository/configuracao_app_repository.dart';
import 'package:app/features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DeviceInfo.instance.initialize();
  configDependencies();
  // Aplica o tema e o idioma escolhidos pelo usuário já na abertura do app.
  await locator<AppConfig>().load();
  // Chaves do app (criptografia e access token), sem segurar a abertura. Se falhar (ex.: sem rede),
  // login/registro tentam de novo antes de criptografar a senha.
  unawaited(ConfiguracaoAppUseCase(configuracaoAppRepository: locator<ConfiguracaoAppRepository>()).carregar());
  runApp(const MyApp());
}
