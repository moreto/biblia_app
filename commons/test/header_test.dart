import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthSession.instance.clear();
    AppSession.instance.clear();
  });
  tearDown(() {
    AuthSession.instance.clear();
    AppSession.instance.clear();
  });

  test('minimal não acrescenta headers de acesso', () {
    final header = Header.getHeader(HeaderType.minimal);

    expect(header.containsKey('x-access-token'), isFalse);
    expect(header.containsKey('x-token'), isFalse);
  });

  test('basicInfo usa o access token da AppSession e vai vazio sem ele', () {
    expect(Header.getHeader(HeaderType.basicInfo)['x-access-token'], kVazio);
    expect(Header.getHeader(HeaderType.basicInfo)['x-access-interface'], 'App');

    AppSession.instance.setConfiguracao(cryptKeyB64: 'chave', accessTokenId: 'tokenApi');
    expect(Header.getHeader(HeaderType.basicInfo)['x-access-token'], 'tokenApi');
  });

  test('loggedUser e loggedArea sem sessão lançam headerInvalido', () {
    for (final tipo in [HeaderType.loggedUser, HeaderType.loggedArea]) {
      expect(
        () => Header.getHeader(tipo),
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'headerInvalido')),
        reason: tipo.name,
      );
    }
  });

  test('loggedUser leva token e usuário; loggedArea também a empresa', () {
    AuthSession.instance.setLoggedUser(token: 'tk', userId: 5, emprId: 9);

    final user = Header.getHeader(HeaderType.loggedUser);
    expect(user['x-token'], 'tk');
    expect(user['x-user'], '5');
    expect(user.containsKey('x-empresa'), isFalse);

    expect(Header.getHeader(HeaderType.loggedArea)['x-empresa'], '9');
  });

  test('todo endpoint da área logada usa loggedArea', () {
    const publicos = {
      ApiCore.traducao,
      ApiCore.login,
      ApiCore.otpSend,
      ApiCore.otpVerify,
      ApiCore.configuracaoApp,
      ApiCore.registro,
      ApiCore.usuarioAtivacaoConfirmar,
      ApiCore.funcionalidade,
      ApiCore.healt,
    };
    for (final api in ApiCore.values.where((a) => !publicos.contains(a))) {
      expect(api.headerType, HeaderType.loggedArea, reason: api.name);
    }
  });
}
