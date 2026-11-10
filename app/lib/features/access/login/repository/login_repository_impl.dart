import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/login_model.dart';
import '../../../../data/model/usuario/usuario_dispositivo_model.dart';
import 'login_repository.dart';

class LoginRepositoryImpl implements LoginRepository {
  @override
  Future<Result<LoginModel>> login({required String email, required String senha}) =>
      _postLogin(ApiCore.login, {'email': email, 'senha': senha});

  @override
  Future<Result<LoginModel>> otpVerify({required String email, required String otp}) =>
      _postLogin(ApiCore.otpVerify, {'email': email, 'otp': otp});

  @override
  Future<Result<void>> otpSend({required String email}) async {
    try {
      final response = await DioProvider.of(ApiCore.otpSend).request(verb: Verb.post, body: {'email': email});
      switch (response) {
        case Ok():
          return const Result.ok(null);
        case Error(error: final error):
          return Result.error(error);
      }
    } catch (error) {
      return Result.error(_toException(error));
    }
  }

  @override
  Future<Result<UsuarioDispositivoModel>> registrarDispositivo(UsuarioDispositivoModel dispositivo) async {
    try {
      final response = await DioProvider.of(ApiCore.usuarioDispositivo)
          .request(verb: Verb.post, body: dispositivo.toJson());
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(UsuarioDispositivoModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'respostaApiInvalida'));
    } catch (error) {
      return Result.error(_toException(error));
    }
  }

  Future<Result<LoginModel>> _postLogin(ApiCore api, Map<String, dynamic> body) async {
    try {
      final response = await DioProvider.of(api).request(verb: Verb.post, body: body);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(LoginModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } catch (error) {
      return Result.error(_toException(error));
    }
  }

  Exception _toException(Object error) => error is Exception ? error : Exception(error.toString());
}
