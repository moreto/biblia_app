import 'package:app/data/model/configuracao/configuracao_app_model.dart';
import 'package:app/data/model/login_model.dart';
import 'package:app/data/model/usuario/usuario_dispositivo_model.dart';
import 'package:app/features/access/configuracao_app/repository/configuracao_app_repository.dart';
import 'package:app/features/access/configuracao_app/use_case/configuracao_app_usecase.dart';
import 'package:app/features/access/login/repository/login_repository.dart';
import 'package:app/features/access/login/use_case/login_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _chave = '5oAaa+hIOTQzGUxHYn8o6mHfQqEi9PXb4kBGpCQ+fn0=';

class _FakeConfiguracaoAppRepository implements ConfiguracaoAppRepository {
  @override
  Future<Result<List<ConfiguracaoAppModel>>> listar() async =>
      const Result.ok([ConfiguracaoAppModel(citeChave: kConfCryptKeyB64, citeValor: _chave)]);
}

class _FakeLoginRepository implements LoginRepository {
  _FakeLoginRepository(this.resposta);

  final Result<LoginModel> resposta;
  String? senhaRecebida;
  int chamadas = 0;

  @override
  Future<Result<LoginModel>> login({required String email, required String senha}) async {
    chamadas++;
    senhaRecebida = senha;
    return resposta;
  }

  @override
  Future<Result<void>> otpSend({required String email}) async {
    chamadas++;
    return const Result.ok(null);
  }

  @override
  Future<Result<LoginModel>> otpVerify({required String email, required String otp}) async {
    chamadas++;
    return resposta;
  }

  final dispositivos = <UsuarioDispositivoModel>[];
  Result<UsuarioDispositivoModel>? respostaDispositivo;

  @override
  Future<Result<UsuarioDispositivoModel>> registrarDispositivo(UsuarioDispositivoModel dispositivo) async {
    dispositivos.add(dispositivo);
    return respostaDispositivo ?? Result.ok(dispositivo);
  }
}

const _aparelho = UsuarioDispositivoModel(
  udisDeviceId: 'abc123',
  udisNome: ' Pixel 8 ',
  udisSistemaOperacional: 'Android 15',
);

LoginUseCase _useCase(_FakeLoginRepository repo, {DispositivoAtual? dispositivo}) => LoginUseCase(
  loginRepository: repo,
  configuracaoAppUseCase: ConfiguracaoAppUseCase(configuracaoAppRepository: _FakeConfiguracaoAppRepository()),
  dispositivo: dispositivo ?? () async => _aparelho,
);

String? _mensagem(Result<Object?> result) => switch (result) {
  Error(error: HandledException(message: final m)) => m,
  _ => null,
};

void main() {
  setUp(() {
    AuthSession.instance.clear();
    AppSession.instance.clear();
  });
  tearDown(() {
    AuthSession.instance.clear();
    AppSession.instance.clear();
  });

  group('validações', () {
    final useCase = _useCase(_FakeLoginRepository(Result.ok(LoginModel(usuaId: 1, token: 'tk'))));

    test('e-mail', () {
      expect(useCase.validateEmail(''), 'emailObrigatorio');
      expect(useCase.validateEmail('a@b'), 'emailInvalido');
      expect(useCase.validateEmail(' a@b.com '), isNull);
    });

    test('senha e código', () {
      expect(useCase.validateSenha(''), 'informeSenha');
      expect(useCase.validateCodigo('12345'), 'informeCodigo6Digitos');
      expect(useCase.validateCodigo('12a456'), 'informeCodigo6Digitos');
      expect(useCase.validateCodigo('123456'), isNull);
    });

    test('mensagem de erro', () {
      expect(useCase.errorMessage(HandledException(message: 'x')), 'x');
      expect(useCase.errorMessage(HttpServiceException(message: 'erroApi')), 'erroApi');
      expect(useCase.errorMessage(Exception()), kDefaultAppError);
    });
  });

  test('login válido criptografa a senha e grava a sessão', () async {
    final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));

    final result = await _useCase(repo).login(email: ' a@b.com ', senha: 'segredo');

    expect(result, isA<Ok<LoginModel>>());
    expect(repo.senhaRecebida, isNot('segredo'));
    expect(await Encrypt().decryptString(repo.senhaRecebida!, _chave), 'segredo');
    expect(AuthSession.instance.isLogged, isTrue);
    expect(AuthSession.instance.userId, 7);
  });

  test('login inválido não chama a API', () async {
    final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));

    final result = await _useCase(repo).login(email: 'a@b.com', senha: '');

    expect(_mensagem(result), 'informeSenha');
    expect(repo.chamadas, 0);
  });

  test('token vazio da API vira tokenInvalido e não grava a sessão', () async {
    final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: '')));

    final result = await _useCase(repo).otpVerify(email: 'a@b.com', otp: '123456');

    expect(_mensagem(result), 'tokenInvalido');
    expect(AuthSession.instance.isLogged, isFalse);
  });

  test('erro da API é repassado sem gravar a sessão', () async {
    final repo = _FakeLoginRepository(Result.error(HttpServiceException(message: 'usuarioSenhaInvalidos', code: 401)));

    final result = await _useCase(repo).login(email: 'a@b.com', senha: 'x');

    expect(result, isA<Error<LoginModel>>());
    expect(AuthSession.instance.isLogged, isFalse);
  });

  group('registro do dispositivo', () {
    test('login por senha com sucesso registra o aparelho (textos aparados)', () async {
      final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));

      await _useCase(repo).login(email: 'a@b.com', senha: 'segredo');
      await pumpEventQueue();

      final enviado = repo.dispositivos.single;
      expect(
        (enviado.udisDeviceId, enviado.udisNome, enviado.udisSistemaOperacional),
        ('abc123', 'Pixel 8', 'Android 15'),
      );
    });

    test('login por código com sucesso também registra', () async {
      final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));

      await _useCase(repo).otpVerify(email: 'a@b.com', otp: '123456');
      await pumpEventQueue();

      expect(repo.dispositivos, hasLength(1));
    });

    test('login com erro ou token inválido não registra', () async {
      final erro = _FakeLoginRepository(Result.error(HttpServiceException(message: 'usuarioSenhaInvalidos')));
      await _useCase(erro).login(email: 'a@b.com', senha: 'x');
      final semToken = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: '')));
      await _useCase(semToken).otpVerify(email: 'a@b.com', otp: '123456');
      await pumpEventQueue();

      expect(erro.dispositivos, isEmpty);
      expect(semToken.dispositivos, isEmpty);
    });

    test('aparelho sem informações (web/desktop) não chama a API e não afeta o login', () async {
      final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));
      final useCase = _useCase(repo, dispositivo: () async => throw UnsupportedError('desktop'));

      final result = await useCase.login(email: 'a@b.com', senha: 'segredo');
      await pumpEventQueue();

      expect(result, isA<Ok<LoginModel>>());
      expect(repo.dispositivos, isEmpty);
      expect(_mensagem(await useCase.registrarDispositivo()), 'dispositivoIndisponivel');
    });

    test('erro da API no registro não afeta o login', () async {
      final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')))
        ..respostaDispositivo = Result.error(HttpServiceException(message: 'erroGeralApi', code: 500));

      final result = await _useCase(repo).login(email: 'a@b.com', senha: 'segredo');
      await pumpEventQueue();

      expect(result, isA<Ok<LoginModel>>());
      expect(AuthSession.instance.isLogged, isTrue);
      expect(repo.dispositivos, hasLength(1));
    });

    test('corta nos tamanhos das colunas e exige os três campos', () async {
      AuthSession.instance.setLoggedUser(token: 'tk', userId: 7);
      final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));
      final longo = _useCase(
        repo,
        dispositivo: () async =>
            UsuarioDispositivoModel(udisDeviceId: 'i' * 100, udisNome: 'n' * 100, udisSistemaOperacional: 's' * 70),
      );

      expect(await longo.registrarDispositivo(), isA<Ok<void>>());
      final enviado = repo.dispositivos.single;
      expect(
        (enviado.udisDeviceId.length, enviado.udisNome.length, enviado.udisSistemaOperacional.length),
        (90, 90, 60),
      );

      final semNome = _useCase(
        repo,
        dispositivo: () async =>
            const UsuarioDispositivoModel(udisDeviceId: 'x', udisNome: ' ', udisSistemaOperacional: 'iOS'),
      );
      expect(_mensagem(await semNome.registrarDispositivo()), 'dispositivoIndisponivel');
      expect(repo.dispositivos, hasLength(1));
    });

    test('sem sessão não registra', () async {
      final repo = _FakeLoginRepository(Result.ok(LoginModel(usuaId: 7, token: 'tk')));
      expect(_mensagem(await _useCase(repo).registrarDispositivo()), 'tokenInvalido');
      expect(repo.dispositivos, isEmpty);
    });

    test('UsuarioDispositivoModel lê a resposta da API e envia só os campos do corpo', () {
      final model = UsuarioDispositivoModel.fromJson({
        'udisId': '3',
        'usua_id': 7,
        'udisDeviceId': 'abc',
        'udisNome': 'Pixel',
        'udisSistemaOperacional': 'Android 15',
      });
      expect((model.udisId, model.usuaId, model.udloIp), (3, 7, null));
      expect(model.toJson().keys, ['udisDeviceId', 'udisNome', 'udisSistemaOperacional', 'udloIp']);
    });
  });
}
