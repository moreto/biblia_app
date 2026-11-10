import 'dart:async';

import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../config/device_info.dart';
import '../../../../data/model/login_model.dart';
import '../../../../data/model/usuario/usuario_dispositivo_model.dart';
import '../../configuracao_app/use_case/configuracao_app_usecase.dart';
import '../repository/login_repository.dart';

/// Lê o aparelho atual (id, nome e sistema operacional); lança se a plataforma não tiver essas informações.
typedef DispositivoAtual = Future<UsuarioDispositivoModel> Function();

Future<UsuarioDispositivoModel> _dispositivoDoAparelho() async {
  final info = DeviceInfo.instance;
  await info.initialize();
  return UsuarioDispositivoModel(
    udisDeviceId: info.deviceId,
    udisNome: info.name,
    udisSistemaOperacional: info.operatingSystem,
  );
}

/// Regras de negócio do login. As validações devolvem a chave de tradução do erro, ou null se o valor é válido.
///
/// Login com sucesso (senha ou código) grava a sessão e registra o aparelho do usuário
/// (`POST /v1/usuario-dispositivo`, [registrarDispositivo]) em segundo plano: o login não espera nem falha por
/// causa do registro.
class LoginUseCase {
  LoginUseCase({required this.loginRepository, required this.configuracaoAppUseCase, DispositivoAtual? dispositivo})
    : _dispositivo = dispositivo ?? _dispositivoDoAparelho;

  /// Tamanhos das colunas de `public.usuario_dispositivo` (id, nome e sistema operacional).
  static const kDeviceIdMax = 90;
  static const kNomeDispositivoMax = 90;
  static const kSistemaOperacionalMax = 60;

  final DispositivoAtual _dispositivo;

  final LoginRepository loginRepository;

  /// Fornece a chave de criptografia da senha, lida de `GET /v1/configuracao-app`.
  final ConfiguracaoAppUseCase configuracaoAppUseCase;
  final Encrypt _encrypt = Encrypt();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _codigoRegex = RegExp(r'^\d{6}$');

  // ---------- validações ----------

  String? validateEmail(String? email) {
    final value = email?.trim() ?? kVazio;
    if (value.isEmpty) return 'emailObrigatorio';
    if (!_emailRegex.hasMatch(value)) return 'emailInvalido';
    return null;
  }

  String? validateSenha(String? senha) {
    if (senha == null || senha.isEmpty) return 'informeSenha';
    return null;
  }

  String? validateCodigo(String? codigo) {
    if (!_codigoRegex.hasMatch(codigo?.trim() ?? kVazio)) return 'informeCodigo6Digitos';
    return null;
  }

  /// Chave de tradução da mensagem de um erro devolvido pelas operações de login.
  String errorMessage(Exception error) => switch (error) {
    HandledException(message: final message) => message,
    HttpServiceException(message: final message?) => message,
    _ => kDefaultAppError,
  };

  // ---------- operações ----------

  /// Valida os dados, criptografa a senha com a chave compartilhada com a API e, se der certo, grava a sessão.
  Future<Result<LoginModel>> login({required String email, required String senha}) async {
    final invalid = validateEmail(email) ?? validateSenha(senha);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    final String chave;
    switch (await configuracaoAppUseCase.cryptKeyB64()) {
      case Ok<String>(value: final value):
        chave = value;
      case Error<String>(error: final error):
        return Result.error(error);
    }

    final String senhaCriptografada;
    try {
      senhaCriptografada = await _encrypt.encryptString(senha, chave);
    } catch (_) {
      return Result.error(HandledException(message: kDefaultAppError));
    }

    final result = await loginRepository.login(email: email.trim(), senha: senhaCriptografada);
    return _logado(_saveSession(result));
  }

  Future<Result<void>> otpSend({required String email}) async {
    final invalid = validateEmail(email);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    return loginRepository.otpSend(email: email.trim());
  }

  Future<Result<LoginModel>> otpVerify({required String email, required String otp}) async {
    final invalid = validateEmail(email) ?? validateCodigo(otp);
    if (invalid != null) return Result.error(HandledException(message: invalid));

    final result = await loginRepository.otpVerify(email: email.trim(), otp: otp.trim());
    return _logado(_saveSession(result));
  }

  /// Registra o aparelho do usuário logado. Sem informações do aparelho (ex.: web/desktop) ou sem sessão, não
  /// chama a API. Textos vão aparados e cortados no tamanho das colunas. Erros só vão para o log.
  Future<Result<void>> registrarDispositivo() async {
    if (!AuthSession.instance.isLogged) return Result.error(HandledException(message: 'tokenInvalido'));

    final UsuarioDispositivoModel aparelho;
    try {
      aparelho = await _dispositivo();
    } catch (error) {
      Log.print('Dispositivo não registrado: $error', name: kApp, title: 'Dispositivo');
      return Result.error(HandledException(message: 'dispositivoIndisponivel'));
    }

    final dispositivo = UsuarioDispositivoModel(
      udisDeviceId: _corta(aparelho.udisDeviceId, kDeviceIdMax),
      udisNome: _corta(aparelho.udisNome, kNomeDispositivoMax),
      udisSistemaOperacional: _corta(aparelho.udisSistemaOperacional, kSistemaOperacionalMax),
      udloIp: aparelho.udloIp,
    );
    if (dispositivo.udisDeviceId.isEmpty ||
        dispositivo.udisNome.isEmpty ||
        dispositivo.udisSistemaOperacional.isEmpty) {
      return Result.error(HandledException(message: 'dispositivoIndisponivel'));
    }

    final result = await loginRepository.registrarDispositivo(dispositivo);
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Dispositivo');
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(error: final error) => Result.error(error),
    };
  }

  /// Depois de um login com sucesso, dispara o registro do aparelho sem esperar.
  Result<LoginModel> _logado(Result<LoginModel> result) {
    if (result is Ok) unawaited(registrarDispositivo());
    return result;
  }

  static String _corta(String valor, int maximo) {
    final texto = valor.trim();
    return texto.length <= maximo ? texto : texto.substring(0, maximo);
  }

  Result<LoginModel> _saveSession(Result<LoginModel> result) {
    switch (result) {
      case Ok<LoginModel>(value: final value):
        try {
          AuthSession.instance.setLoggedUser(token: value.token, userId: value.usuaId);
        } on ArgumentError catch (error) {
          return Result.error(HandledException(message: error.message?.toString() ?? 'tokenInvalido'));
        }
        return result;
      case Error<LoginModel>():
        return result;
    }
  }
}
