import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/versiculo_renomado_model.dart';
import 'versiculo_renomado_repository.dart';

class VersiculoRenomadoRepositoryImpl implements VersiculoRenomadoRepository {
  @override
  Future<Result<List<VersiculoRenomadoModel>>> versiculos(int renoId, int versaId) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoRenomado)
          .request(verb: Verb.get, pathParam: '$renoId/$versaId');
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoVersiculoRenomadoInvalido');
                  }
                  return VersiculoRenomadoModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoVersiculoRenomadoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
