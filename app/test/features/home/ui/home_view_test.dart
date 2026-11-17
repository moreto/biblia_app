import 'package:app/features/access/home/ui/home_view.dart';
import 'package:app/features/access/home/ui/home_viewmodel.dart';
import 'package:app/features/access/home/use_case/home_usecase.dart';
import 'package:commons/commons.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Textos aparecem como as próprias chaves (`find.text('biblia')`).
class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale: locale, translations: const []));

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

void main() {
  HomeViewmodel criar([LerIdDispositivo? lerIdDispositivo]) =>
      HomeViewmodel(homeUseCase: HomeUseCase(lerIdDispositivo: lerIdDispositivo ?? () async => 'abc123'));

  Future<void> montar(WidgetTester tester, [HomeViewmodel? viewModel]) async {
    final vm = viewModel ?? criar();
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => HomeView(viewModel: vm),
        ),
        GoRoute(
          path: Routes.bibliaLeitura,
          builder: (context, state) => const Scaffold(body: Text('telaLeitura')),
        ),
        GoRoute(
          path: Routes.homeOld,
          builder: (context, state) => const Scaffold(body: Text('telaHomeOld')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HomeUseCase.idDispositivo', () {
    test('devolve o id lido do aparelho', () async {
      final result = await HomeUseCase(lerIdDispositivo: () async => 'abc123').idDispositivo();
      expect((result as Ok<String>).value, 'abc123');
    });

    test('plataforma sem id (web/desktop) vira dispositivoNaoIdentificado', () async {
      final result = await HomeUseCase(lerIdDispositivo: () async => throw UnsupportedError('web')).idDispositivo();
      expect(((result as Error<String>).error as HandledException).message, 'dispositivoNaoIdentificado');
    });

    test('id vazio vira dispositivoNaoIdentificado', () async {
      final result = await HomeUseCase(lerIdDispositivo: () async => '').idDispositivo();
      expect(((result as Error<String>).error as HandledException).message, 'dispositivoNaoIdentificado');
    });
  });

  testWidgets('mostra o id do aparelho embaixo do botão Bíblia', (tester) async {
    await montar(tester);

    final botao = tester.getCenter(find.widgetWithText(FilledButton, 'biblia'));
    final id = tester.getCenter(find.text('abc123'));
    expect(id.dy, greaterThan(botao.dy));
  });

  testWidgets('sem id mostra dispositivoNaoIdentificado', (tester) async {
    await montar(tester, criar(() async => throw UnsupportedError('web')));

    expect(find.text('dispositivoNaoIdentificado'), findsOneWidget);
  });

  testWidgets('mostra o título e o botão Bíblia', (tester) async {
    await montar(tester);

    expect(find.text('home'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'biblia'), findsOneWidget);
  });

  testWidgets('o ícone do menu hambúrguer abre o Drawer', (tester) async {
    await montar(tester);

    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('menus'), findsOneWidget);
  });

  testWidgets('a opção Home antiga do menu fecha o Drawer e abre /home-old', (tester) async {
    await montar(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('homeAntiga'));
    await tester.pumpAndSettle();

    expect(find.text('telaHomeOld'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('o botão Bíblia abre a leitura', (tester) async {
    await montar(tester);

    await tester.tap(find.text('biblia'));
    await tester.pumpAndSettle();

    expect(find.text('telaLeitura'), findsOneWidget);
  });
}
