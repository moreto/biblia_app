import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/registro_model.dart';
import 'registro_repository.dart';

class RegistroRepositoryImpl implements RegistroRepository {
  @override
  Future<Result<RegistroModel>> registrar({required String email, required String senha}) async {
    try {
      final response = await DioProvider.of(
        ApiCore.registro,
      ).request(verb: Verb.post, body: {'email': email, 'senha': senha});
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(RegistroModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on TypeError {
      return Result.error(HandledException(message: 'respostaApiInvalida'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  @override
  Future<Result<void>> ativar({required String email, required String codigo}) async {
    try {
      final response = await DioProvider.of(
        ApiCore.usuarioAtivacaoConfirmar,
      ).request(verb: Verb.post, body: {'email': email, 'key': codigo});
      switch (response) {
        case Ok():
          return const Result.ok(null);
        case Error(error: final error):
          return Result.error(error);
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
