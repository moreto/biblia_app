import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/versiculo/versiculo_reacao_model.dart';
import 'versiculo_reacao_repository.dart';

class VersiculoReacaoRepositoryImpl implements VersiculoReacaoRepository {
  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoReacao).request(verb: Verb.get, pathParam: versId);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoReacaoInvalido');
                  }
                  return VersiculoReacaoModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoReacaoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoReacaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  @override
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao) => _gravar(Verb.post, reacao);

  @override
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao) => _gravar(Verb.put, reacao);

  Future<Result<VersiculoReacaoModel>> _gravar(Verb verb, VersiculoReacaoModel reacao) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoReacao).request(verb: verb, body: reacao.toJson());
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(VersiculoReacaoModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoReacaoInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoReacaoInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
