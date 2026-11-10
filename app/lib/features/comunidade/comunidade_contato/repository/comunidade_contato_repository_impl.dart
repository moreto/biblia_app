import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';
import 'comunidade_contato_repository.dart';

class ComunidadeContatoRepositoryImpl implements ComunidadeContatoRepository {
  @override
  Future<Result<List<ComunidadeContatoModel>>> contatos(int comuId) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeContato).request(verb: Verb.get, pathParam: comuId);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) throw const FormatException(kFormatoInvalido);
                  return ComunidadeContatoModel.fromJson(Map<String, dynamic>.from(item));
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

  @override
  Future<Result<ComunidadeContatoModel>> incluir(ComunidadeContatoModel contato) => _gravar(Verb.post, contato);

  @override
  Future<Result<ComunidadeContatoModel>> alterar(ComunidadeContatoModel contato) => _gravar(Verb.put, contato);

  @override
  Future<Result<void>> excluir(int cconId) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeContato).request(verb: Verb.delete, pathParam: cconId);
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

  /// POST/PUT com o corpo de [ComunidadeContatoModel.toJson]; devolve o registro gravado.
  Future<Result<ComunidadeContatoModel>> _gravar(Verb verb, ComunidadeContatoModel contato) async {
    try {
      final response = await DioProvider.of(ApiCore.comunidadeContato).request(verb: verb, body: contato.toJson());
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(ComunidadeContatoModel.fromJson(Map<String, dynamic>.from(value)));
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

  /// Resposta da API fora do formato do [ComunidadeContatoModel].
  static const kFormatoInvalido = 'formatoContatoInvalido';
}
