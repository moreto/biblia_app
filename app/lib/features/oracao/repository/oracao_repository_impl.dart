import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/oracao/oracao_model.dart';
import 'oracao_repository.dart';

class OracaoRepositoryImpl implements OracaoRepository {
  @override
  Future<Result<OracaoModel>> aleatoria() async {
    try {
      final response = await DioProvider.of(ApiCore.oracaoAleatoria).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(OracaoModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoOracaoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoOracaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
