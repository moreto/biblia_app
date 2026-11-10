import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/renomado_model.dart';
import 'renomado_repository.dart';

class RenomadoRepositoryImpl implements RenomadoRepository {
  @override
  Future<Result<List<RenomadoModel>>> getAll() async {
    try {
      final response = await DioProvider.of(ApiCore.renomado).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoRenomadoInvalido');
                  }
                  return RenomadoModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoRenomadoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
