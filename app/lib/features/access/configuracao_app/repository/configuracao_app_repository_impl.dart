import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/configuracao/configuracao_app_model.dart';
import 'configuracao_app_repository.dart';

class ConfiguracaoAppRepositoryImpl implements ConfiguracaoAppRepository {
  @override
  Future<Result<List<ConfiguracaoAppModel>>> listar() async {
    try {
      final response = await DioProvider.of(ApiCore.configuracaoApp).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoConfiguracaoAppInvalido');
                  }
                  return ConfiguracaoAppModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoConfiguracaoAppInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoConfiguracaoAppInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
