import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/providers.dart';
import 'l10n/app_localizations.dart';
import 'routing/router.dart';

final _appRouter = router();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: configProviders(),
      child: Consumer<AppConfig>(
        builder: (context, themeController, child) {
          return MaterialApp.router(
            // scrollBehavior: AppCustomScrollBehavior(),
            theme: AppTheme.lightTheme(font: themeController.font),
            darkTheme: AppTheme.darkTheme(font: themeController.font),
            themeMode: themeController.mode,
            locale: themeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _appRouter,
          );
        },
      ),
    );
  }
}
