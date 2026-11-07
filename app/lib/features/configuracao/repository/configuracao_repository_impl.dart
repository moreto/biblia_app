import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import 'configuracao_repository.dart';

class ConfiguracaoRepositoryImpl implements ConfiguracaoRepository {
  // configuracao

  @override
  Future<Result<List<ConfiguracaoModel>>> getConfiguracoes() =>
      _requestList(ApiCore.configuracao, ConfiguracaoModel.fromJson);

  @override
  Future<Result<ConfiguracaoModel>> insertConfiguracao(ConfiguracaoModel configuracao) =>
      _requestOne(ApiCore.configuracao, Verb.post, ConfiguracaoModel.fromJson, body: configuracao.toJson());

  @override
  Future<Result<ConfiguracaoModel>> updateConfiguracao(ConfiguracaoModel configuracao) =>
      _requestOne(ApiCore.configuracao, Verb.put, ConfiguracaoModel.fromJson, body: configuracao.toJson());

  @override
  Future<Result<int>> deleteConfiguracao(int confId) => _requestDelete(ApiCore.configuracao, confId, 'confId');

  // configuracao-item

  @override
  Future<Result<List<ConfiguracaoItemModel>>> getItens(int confId) =>
      _requestList(ApiCore.configuracaoItem, ConfiguracaoItemModel.fromJson, pathParam: confId);

  @override
  Future<Result<ConfiguracaoItemModel>> insertItem(ConfiguracaoItemModel item) =>
      _requestOne(ApiCore.configuracaoItem, Verb.post, ConfiguracaoItemModel.fromJson, body: item.toJson());

  @override
  Future<Result<ConfiguracaoItemModel>> updateItem(ConfiguracaoItemModel item) =>
      _requestOne(ApiCore.configuracaoItem, Verb.put, ConfiguracaoItemModel.fromJson, body: item.toJson());

  @override
  Future<Result<int>> deleteItem(int citeId) => _requestDelete(ApiCore.configuracaoItem, citeId, 'citeId');

  // helpers

  Future<Result<List<T>>> _requestList<T>(
    ApiCore apiCore,
    T Function(Map<String, dynamic>) fromJson, {
    Object? pathParam,
  }) async {
    try {
      final response = await DioProvider.of(apiCore).request(verb: Verb.get, pathParam: pathParam);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoConfiguracaoInvalido');
                  }
                  return fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoConfiguracaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  Future<Result<T>> _requestOne<T>(
    ApiCore apiCore,
    Verb verb,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await DioProvider.of(apiCore).request(verb: verb, body: body);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoConfiguracaoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoConfiguracaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  Future<Result<int>> _requestDelete(ApiCore apiCore, int id, String idKey) async {
    try {
      final response = await DioProvider.of(apiCore).request(verb: Verb.delete, pathParam: id);
      switch (response) {
        case Ok(value: final value) when value is Map && value[idKey] is num:
          return Result.ok((value[idKey] as num).toInt());
        case Ok():
          return Result.ok(id);
        case Error(error: final error):
          return Result.error(error);
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
