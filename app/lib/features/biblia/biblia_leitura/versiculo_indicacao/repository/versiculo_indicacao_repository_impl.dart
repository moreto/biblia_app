import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/biblia/versiculo_indicacao_model.dart';
import 'versiculo_indicacao_repository.dart';

class VersiculoIndicacaoRepositoryImpl implements VersiculoIndicacaoRepository {
  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoes(int versId) => _lista(ApiCore.versiculoIndicacao, versId);

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoesCapitulo(int versaId, int livrId, int capiNumero) =>
      _lista(ApiCore.versiculoIndicacaoCapitulo, '$versaId/$livrId/$capiNumero');

  Future<Result<List<VersiculoIndicacaoModel>>> _lista(ApiCore api, Object pathParam) async {
    try {
      final response = await DioProvider.of(api).request(verb: Verb.get, pathParam: pathParam);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoIndicacaoInvalido');
                  }
                  return VersiculoIndicacaoModel.fromJson(Map<String, dynamic>.from(item));
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

  @override
  Future<Result<VersiculoIndicacaoModel>> incluir(VersiculoIndicacaoModel indicacao) => _gravar(Verb.post, indicacao);

  @override
  Future<Result<VersiculoIndicacaoModel>> alterar(VersiculoIndicacaoModel indicacao) => _gravar(Verb.put, indicacao);

  @override
  Future<Result<void>> excluir(int vindId) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoIndicacao).request(verb: Verb.delete, pathParam: vindId);
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

  Future<Result<VersiculoIndicacaoModel>> _gravar(Verb verb, VersiculoIndicacaoModel indicacao) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoIndicacao).request(verb: verb, body: indicacao.toJson());
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(VersiculoIndicacaoModel.fromJson(Map<String, dynamic>.from(value)));
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
