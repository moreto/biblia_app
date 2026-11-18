import 'package:commons/commons.dart';

/// Conversão das respostas da API dos grupos de leitura, usada pelos repositories de `features/grupo_leitura`.
///
/// Resposta fora do formato vira `respostaApiInvalida` (tipo inesperado) ou [kFormatoInvalido] (campo inválido no
/// JSON); erro da API ou do DioProvider é repassado.
abstract final class LeituraResposta {
  /// Resposta da API fora do formato esperado.
  static const kFormatoInvalido = 'formatoGrupoLeituraInvalido';

  /// Resposta que precisa ser uma lista de objetos, convertidos por [fromJson].
  static Future<Result<List<T>>> lista<T>(
    Future<Result<dynamic>> requisicao,
    T Function(Map<String, dynamic>) fromJson,
  ) => _converter(requisicao, (value) {
    if (value is! List) return null;
    return value
        .map((item) {
          if (item is! Map) throw const FormatException(kFormatoInvalido);
          return fromJson(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  });

  /// Resposta que precisa ser um objeto, convertido por [fromJson].
  static Future<Result<T>> objeto<T>(Future<Result<dynamic>> requisicao, T Function(Map<String, dynamic>) fromJson) =>
      _converter(requisicao, (value) => value is Map ? fromJson(Map<String, dynamic>.from(value)) : null);

  /// DELETE: o corpo (`{ id }`) não é usado.
  static Future<Result<void>> excluir(Future<Result<dynamic>> requisicao) async {
    try {
      return switch (await requisicao) {
        Ok() => const Result.ok(null),
        Error(error: final error) => Result.error(error),
      };
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// [converter] devolve nulo quando o tipo da resposta não é o esperado.
  static Future<Result<T>> _converter<T>(
    Future<Result<dynamic>> requisicao,
    T? Function(Object? value) converter,
  ) async {
    try {
      switch (await requisicao) {
        case Ok(value: final value):
          final convertido = converter(value);
          return convertido == null
              ? Result.error(HandledException(message: 'respostaApiInvalida'))
              : Result.ok(convertido);
        case Error(error: final error):
          return Result.error(error);
      }
    } on FormatException {
      return Result.error(HandledException(message: kFormatoInvalido));
    } on TypeError {
      return Result.error(HandledException(message: kFormatoInvalido));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
