import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/versiculo/versiculo_model.dart';
import 'versiculo_repository.dart';

class VersiculoRepositoryImpl implements VersiculoRepository {
  @override
  Future<Result<VersiculoModel>> aleatorio() async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoAleatorio).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(VersiculoModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoVersiculoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoVersiculoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
