import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession', () {
    tearDown(AuthSession.instance.clear);

    test('grava e limpa o usuário logado', () {
      AuthSession.instance.setLoggedUser(token: 'tk', userId: 3);
      expect(AuthSession.instance.isLogged, isTrue);

      AuthSession.instance.clear();
      expect(AuthSession.instance.isLogged, isFalse);
      expect(AuthSession.instance.token, isNull);
    });

    test('recusa token vazio ou usuário inválido', () {
      expect(() => AuthSession.instance.setLoggedUser(token: '', userId: 1), throwsArgumentError);
      expect(() => AuthSession.instance.setLoggedUser(token: 'tk', userId: 0), throwsArgumentError);
      expect(() => AuthSession.instance.setEmpresa(emprId: 0), throwsArgumentError);
      expect(AuthSession.instance.isLogged, isFalse);
    });
  });

  group('AppSession', () {
    tearDown(AppSession.instance.clear);

    test('access token vazio vira nulo', () {
      AppSession.instance.setConfiguracao(cryptKeyB64: 'chave', accessTokenId: '');

      expect(AppSession.instance.isLoaded, isTrue);
      expect(AppSession.instance.accessTokenId, isNull);
    });

    test('recusa chave vazia', () {
      expect(() => AppSession.instance.setConfiguracao(cryptKeyB64: ''), throwsArgumentError);
      expect(AppSession.instance.isLoaded, isFalse);
    });
  });
}
