import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/log_model.dart';
import 'log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  @override
  Future<Result<List<LogModel>>> getLogs() async {
    try {
      final response = await DioProvider.of(ApiCore.log).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoLogInvalido');
                  }
                  return LogModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoLogInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
