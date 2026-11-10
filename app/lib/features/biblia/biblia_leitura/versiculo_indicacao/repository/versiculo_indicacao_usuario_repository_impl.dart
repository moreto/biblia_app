import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/biblia/versiculo_indicacao_usuario_model.dart';
import '../../../../../data/model/usuario/usuario_resumo_model.dart';
import 'versiculo_indicacao_usuario_repository.dart';

class VersiculoIndicacaoUsuarioRepositoryImpl implements VersiculoIndicacaoUsuarioRepository {
  @override
  Future<Result<List<VersiculoIndicacaoUsuarioModel>>> usuarios(int vindId) => _lista(
    DioProvider.of(ApiCore.versiculoIndicacaoUsuario).request(verb: Verb.get, pathParam: vindId),
    VersiculoIndicacaoUsuarioModel.fromJson,
  );

  @override
  Future<Result<VersiculoIndicacaoUsuarioModel>> incluir({required int vindId, required int usuaId}) =>
      _gravar(Verb.post, {'vindId': vindId, 'usuaId': usuaId});

  @override
  Future<Result<VersiculoIndicacaoUsuarioModel>> alterar({
    required int viusId,
    required int vindId,
    required int usuaId,
  }) => _gravar(Verb.put, {'viusId': viusId, 'vindId': vindId, 'usuaId': usuaId});

  @override
  Future<Result<void>> excluir(int viusId) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoIndicacaoUsuario)
          .request(verb: Verb.delete, pathParam: viusId);
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

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) => _lista(
    DioProvider.of(ApiCore.usuarioBusca).request(verb: Verb.get, queryParam: {'texto': texto}),
    UsuarioResumoModel.fromJson,
  );

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
                  if (item is! Map) throw const FormatException('formatoIndicacaoInvalido');
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
      return Result.error(HandledException(message: 'formatoIndicacaoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoIndicacaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  Future<Result<VersiculoIndicacaoUsuarioModel>> _gravar(Verb verb, Map<String, dynamic> body) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoIndicacaoUsuario).request(verb: verb, body: body);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(VersiculoIndicacaoUsuarioModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoIndicacaoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoIndicacaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
