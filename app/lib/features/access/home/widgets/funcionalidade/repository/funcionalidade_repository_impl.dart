import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../../data/model/funcionalidade/funcionalidade_model.dart';
import 'funcionalidade_repository.dart';

class FuncionalidadeRepositoryImpl implements FuncionalidadeRepository {
  @override
  Future<Result<List<FuncionalidadeModel>>> listar() async {
    try {
      final response = await DioProvider.of(ApiCore.funcionalidade).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoFuncionalidadeInvalido');
                  }
                  return FuncionalidadeModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoFuncionalidadeInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoFuncionalidadeInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
