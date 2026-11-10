import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/comunidade/comunidade_denominacao_model.dart';
import '../../../data/model/comunidade/comunidade_model.dart';
import '../../../data/model/comunidade/comunidade_tipo_model.dart';
import 'comunidade_repository.dart';

class ComunidadeRepositoryImpl implements ComunidadeRepository {
  @override
  Future<Result<List<ComunidadeModel>>> comunidadesDoUsuario(int usuaId) =>
      _lista(ApiCore.comunidadeUsuario, usuaId, ComunidadeModel.fromJson);

  @override
  Future<Result<List<ComunidadeTipoModel>>> tipos() =>
      _lista(ApiCore.comunidadeTipo, null, ComunidadeTipoModel.fromJson);

  @override
  Future<Result<List<ComunidadeDenominacaoModel>>> denominacoes() =>
      _lista(ApiCore.comunidadeDenominacao, null, ComunidadeDenominacaoModel.fromJson);

  /// GET que devolve uma lista de objetos, convertidos por [fromJson]. Item fora do formato devolve
  /// `formatoComunidadeInvalido`.
  Future<Result<List<T>>> _lista<T>(ApiCore api, Object? pathParam, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await DioProvider.of(api).request(verb: Verb.get, pathParam: pathParam);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoComunidadeInvalido');
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
      return Result.error(HandledException(message: 'formatoComunidadeInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoComunidadeInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
