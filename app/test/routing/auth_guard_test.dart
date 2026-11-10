import 'package:app/routing/auth_guard.dart';
import 'package:app/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authRedirect sem login', () {
    test('rotas públicas seguem', () {
      for (final path in kPublicRoutes) {
        expect(authRedirect(path: path, isLogged: false), isNull, reason: path);
      }
    });

    test('rotas da área logada voltam para a home', () {
      for (final path in [
        Routes.dashboard,
        Routes.loggof,
        Routes.notificacao,
        Routes.log,
        Routes.configuracao,
        Routes.menu,
        Routes.bibliaLeitura,
      ]) {
        expect(authRedirect(path: path, isLogged: false), Routes.home, reason: path);
      }
    });
  });

  group('authRedirect com login', () {
    test('rotas da área logada seguem', () {
      expect(authRedirect(path: Routes.dashboard, isLogged: true), isNull);
      expect(authRedirect(path: Routes.bibliaLeitura, isLogged: true), isNull);
    });

    test('home e login vão para a dashboard', () {
      expect(authRedirect(path: Routes.home, isLogged: true), Routes.dashboard);
      expect(authRedirect(path: Routes.login, isLogged: true), Routes.dashboard);
    });
  });
}
