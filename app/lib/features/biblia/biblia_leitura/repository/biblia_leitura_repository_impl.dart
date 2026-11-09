import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import 'biblia_leitura_repository.dart';

class BibliaLeituraRepositoryImpl implements BibliaLeituraRepository {
  @override
  Future<Result<List<VersaoModel>>> versoes() => _lista(ApiCore.versao, null, VersaoModel.fromJson);

  @override
  Future<Result<List<TestamentoModel>>> testamentos() => _lista(ApiCore.testamento, null, TestamentoModel.fromJson);

  @override
  Future<Result<List<LivroModel>>> livros() => _lista(ApiCore.livro, null, LivroModel.fromJson);

  @override
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId) =>
      _lista(ApiCore.bibliaIndice, versaId, IndiceCapituloModel.fromJson);

  @override
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero) =>
      _lista(ApiCore.bibliaCapitulo, '$versaId/$livrId/$capiNumero', VersiculoTextoModel.fromJson);

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) =>
      _lista(ApiCore.versiculoReacaoLidos, versaId, CapituloLidoModel.fromJson);

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoesCapitulo(int versaId, int livrId, int capiNumero) =>
      _lista(ApiCore.versiculoReacaoCapitulo, '$versaId/$livrId/$capiNumero', VersiculoReacaoModel.fromJson);

  @override
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido}) async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoReacaoCapitulo).request(
        verb: Verb.put,
        body: {'versaId': versaId, 'livrId': livrId, 'capiNumero': capiNumero, 'vreaLido': lido},
      );
      switch (response) {
        case Ok(value: final value) when value is Map:
          final total = value['versTotal'];
          return total is num
              ? Result.ok(total.toInt())
              : Result.error(HandledException(message: 'respostaApiInvalida'));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// GET que devolve uma lista de objetos, convertidos por [fromJson]. Item fora do formato devolve
  /// `formatoLeituraInvalido`.
  Future<Result<List<T>>> _lista<T>(ApiCore api, Object? pathParam, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await DioProvider.of(api).request(verb: Verb.get, pathParam: pathParam);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) {
                    throw const FormatException('formatoLeituraInvalido');
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
      return Result.error(HandledException(message: 'formatoLeituraInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoLeituraInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
