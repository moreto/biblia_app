import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import 'comunidade_lista_repository.dart';

class ComunidadeListaRepositoryImpl implements ComunidadeListaRepository {
  @override
  Future<Result<List<EstadoModel>>> estados() =>
      _lista(DioProvider.of(ApiCore.estado).request(verb: Verb.get), EstadoModel.fromJson);

  @override
  Future<Result<List<MunicipioModel>>> municipios(int estaId) =>
      _lista(DioProvider.of(ApiCore.municipio).request(verb: Verb.get, pathParam: estaId), MunicipioModel.fromJson);

  @override
  Future<Result<List<ComunidadeLocalModel>>> comunidades({required int estaId, int? muniId}) => _lista(
    DioProvider.of(ApiCore.comunidade)
        .request(verb: Verb.get, queryParam: {'estaId': '$estaId', if (muniId != null) 'muniId': '$muniId'}),
    ComunidadeLocalModel.fromJson,
  );

  /// GET que devolve uma lista de objetos, convertidos por [fromJson]. Item fora do formato devolve
  /// [kFormatoInvalido].
  Future<Result<List<T>>> _lista<T>(
    Future<Result<dynamic>> requisicao,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requisicao;
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) throw const FormatException(kFormatoInvalido);
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
      return Result.error(HandledException(message: kFormatoInvalido));
    } on TypeError {
      return Result.error(HandledException(message: kFormatoInvalido));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// Resposta da API fora do formato esperado (chave já existente na API).
  static const kFormatoInvalido = 'formatoComunidadeInvalido';
}
