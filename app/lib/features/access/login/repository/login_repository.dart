import 'package:commons/commons.dart';

import '../../../../data/model/login_model.dart';
import '../../../../data/model/usuario/usuario_dispositivo_model.dart';

abstract class LoginRepository {
  /// POST /v1/acesso/login. [senha] já deve chegar criptografada (AES-256-GCM).
  Future<Result<LoginModel>> login({required String email, required String senha});

  /// POST /v1/otp/send. Responde igual mesmo se o e-mail não existir.
  Future<Result<void>> otpSend({required String email});

  /// POST /v1/otp/verify. Valida o código de 6 dígitos e devolve o login.
  Future<Result<LoginModel>> otpVerify({required String email, required String otp});

  /// POST /v1/usuario-dispositivo. Registra o aparelho do usuário logado e o log de acesso.
  Future<Result<UsuarioDispositivoModel>> registrarDispositivo(UsuarioDispositivoModel dispositivo);
}
