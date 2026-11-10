import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/login_model.dart';
import '../../configuracao_app/use_case/configuracao_app_usecase.dart';
import '../repository/login_repository.dart';

/// Regras de negócio do login. As validações devolvem a chave de tradução do erro, ou null se o valor é válido.
class LoginUseCase {
  LoginUseCase({required this.loginRepository, required this.configuracaoAppUseCase});

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
    return _saveSession(result);
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
    return _saveSession(result);
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
