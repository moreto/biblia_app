import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';
import 'comunidade_endereco_repository.dart';

class ComunidadeEnderecoRepositoryImpl implements ComunidadeEnderecoRepository {
  @override
  Future<Result<List<ComunidadeEnderecoModel>>> enderecos(int comuId) =>
      _lista(ApiCore.comunidadeEndereco, comuId, ComunidadeEnderecoModel.fromJson);

  @override
  Future<Result<List<EstadoModel>>> estados() => _lista(ApiCore.estado, null, EstadoModel.fromJson);

  @override
  Future<Result<List<MunicipioModel>>> municipios(int estaId) =>
      _lista(ApiCore.municipio, estaId, MunicipioModel.fromJson);

  @override
  Future<Result<ComunidadeEnderecoModel>> incluir(ComunidadeEnderecoModel endereco) => _gravar(Verb.post, endereco);

  @override
  Future<Result<ComunidadeEnderecoModel>> alterar(ComunidadeEnderecoModel endereco) => _gravar(Verb.put, endereco);

  @override
  Future<Result<void>> excluir(int cendId) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeEndereco).request(verb: Verb.delete, pathParam: cendId);
      switch (response) {
        case Ok():
          return const Result.ok(null);
        case Error(error: final error):
          return Result.error(error);
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// POST/PUT com o corpo de [ComunidadeEnderecoModel.toJson]; devolve o registro gravado.
  Future<Result<ComunidadeEnderecoModel>> _gravar(Verb verb, ComunidadeEnderecoModel endereco) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeEndereco).request(verb: verb, body: endereco.toJson());
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(ComunidadeEnderecoModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoEnderecoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// GET que devolve uma lista de objetos, convertidos por [fromJson]. Item fora do formato devolve
  /// `formatoEnderecoInvalido`.
  Future<Result<List<T>>> _lista<T>(ApiCore api, Object? pathParam, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await DioProvider.of(api).request(verb: Verb.get, pathParam: pathParam);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoEnderecoInvalido');
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
      return Result.error(HandledException(message: 'formatoEnderecoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoEnderecoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
