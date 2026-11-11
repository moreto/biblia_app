import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_usuario_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import 'comunidade_usuario_repository.dart';

class ComunidadeUsuarioRepositoryImpl implements ComunidadeUsuarioRepository {
  @override
  Future<Result<List<ComunidadeUsuarioModel>>> usuarios(int comuId) => _lista(
    DioProvider.of(ApiCore.comunidadeUsuarioVinculo).request(verb: Verb.get, pathParam: comuId),
    ComunidadeUsuarioModel.fromJson,
  );

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) => _lista(
    DioProvider.of(ApiCore.usuarioBusca).request(verb: Verb.get, queryParam: {'texto': texto}),
    UsuarioResumoModel.fromJson,
  );

  @override
  Future<Result<ComunidadeUsuarioModel>> incluir(ComunidadeUsuarioModel vinculo) => _gravar(Verb.post, vinculo);

  @override
  Future<Result<ComunidadeUsuarioModel>> alterar(ComunidadeUsuarioModel vinculo) => _gravar(Verb.put, vinculo);

  @override
  Future<Result<void>> excluir(int cusuId) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeUsuarioVinculo)
          .request(verb: Verb.delete, pathParam: cusuId);
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

  /// POST/PUT com o corpo de [ComunidadeUsuarioModel.toJson]; devolve o registro gravado (sem o nome).
  Future<Result<ComunidadeUsuarioModel>> _gravar(Verb verb, ComunidadeUsuarioModel vinculo) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeUsuarioVinculo)
          .request(verb: verb, body: vinculo.toJson());
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(ComunidadeUsuarioModel.fromJson(Map<String, dynamic>.from(value)));
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

  /// GET que devolve uma lista de objetos, convertidos por [fromJson].
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

  /// Resposta da API fora do formato esperado.
  static const kFormatoInvalido = 'formatoUsuarioComunidadeInvalido';
}
