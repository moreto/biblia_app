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

    test('a leitura da Bíblia é pública', () {
      expect(authRedirect(path: Routes.bibliaLeitura, isLogged: false), isNull);
    });

    test('as configurações de leitura são públicas, como a leitura', () {
      expect(authRedirect(path: Routes.configuracoesLeitura, isLogged: false), isNull);
      expect(authRedirect(path: Routes.configuracoesLeitura, isLogged: true), isNull);
      expect(authRedirect(path: Routes.versaoBiblia, isLogged: false), Routes.home);
      expect(authRedirect(path: Routes.vozNarracao, isLogged: false), isNull);
    });

    test('/ (sem tela própria) vai para a home', () {
      expect(authRedirect(path: Routes.splash, isLogged: false), Routes.home);
    });

    test('rotas da área logada voltam para a home', () {
      for (final path in [
        Routes.dashboard,
        Routes.loggof,
        Routes.notificacao,
        Routes.log,
        Routes.configuracao,
        Routes.menu,
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
      expect(authRedirect(path: Routes.homeOld, isLogged: true), Routes.dashboard);
      expect(authRedirect(path: Routes.login, isLogged: true), Routes.dashboard);
      expect(authRedirect(path: Routes.splash, isLogged: true), Routes.dashboard);
    });
  });

  group('rotaInicial (ROTA_INICIAL do .env)', () {
    test('vazia ou só espaços abre a home', () {
      expect(rotaInicial(''), Routes.home);
      expect(rotaInicial('   '), Routes.home);
    });

    test('rota preenchida abre direto nela, com query string', () {
      expect(rotaInicial('/dashboard'), Routes.dashboard);
      expect(rotaInicial(' /biblia-leitura?livrId=43&capiNumero=3 '), '/biblia-leitura?livrId=43&capiNumero=3');
    });

    test('valor sem barra no começo é ignorado', () {
      expect(rotaInicial('dashboard'), Routes.home);
    });
  });

  group('rotaInicial continuar', () {
    test('abre a leitura no último capítulo aberto', () {
      expect(
        rotaInicial('continuar', ultimoCapitulo: (versaId: 1, livrId: 43, capiNumero: 3)),
        '/biblia-leitura?versaId=1&livrId=43&capiNumero=3',
      );
    });

    test('sem capítulo guardado abre a home', () {
      expect(rotaInicial(' continuar '), Routes.home);
    });
  });
}
