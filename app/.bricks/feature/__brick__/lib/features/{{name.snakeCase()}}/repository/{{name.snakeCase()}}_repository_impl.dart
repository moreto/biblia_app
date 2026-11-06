import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/healt_model.dart';
import '{{name.snakeCase()}}_repository.dart';

class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  @override
  Future<Result<HealtModel>> healt() async {
    try {
      final response = await DioProvider.of(ApiCore.healt).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(HealtModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'erroApi'));
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
