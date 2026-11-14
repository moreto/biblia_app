import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/dicionario/dicionario_busca_model.dart';
import '../../../../data/model/dicionario/dicionario_verbete_model.dart';
import 'dicionario_repository.dart';

class DicionarioRepositoryImpl implements DicionarioRepository {
  @override
  Future<Result<List<DicionarioBuscaModel>>> buscar(String texto, {required int limite}) => _lista(
    DioProvider.of(ApiCore.dicionarioBusca).request(verb: Verb.get, queryParam: {'texto': texto, 'limite': limite}),
    DicionarioBuscaModel.fromJson,
  );

  /// A palavra vai codificada no path (acentos, espaços e barras).
  @override
  Future<Result<List<DicionarioVerbeteModel>>> palavra(String palavra) => _lista(
    DioProvider.of(ApiCore.dicionarioPalavra).request(verb: Verb.get, pathParam: Uri.encodeComponent(palavra)),
    DicionarioVerbeteModel.fromJson,
  );

  Future<Result<List<T>>> _lista<T>(Future<Result<dynamic>> request, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await request;
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
  static const kFormatoInvalido = 'formatoDicionarioInvalido';
}
