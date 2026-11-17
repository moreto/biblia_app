import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import '../../../data/model/fale_conosco/fale_conosco_model.dart';
import 'fale_conosco_repository.dart';

class FaleConoscoRepositoryImpl implements FaleConoscoRepository {
  @override
  Future<Result<List<FaleConoscoModel>>> meus() =>
      _lista(DioProvider.of(ApiCore.faleConoscoMeus).request(verb: Verb.get), FaleConoscoModel.fromJson);

  @override
  Future<Result<FaleConoscoModel>> meu(int fconId) => _um(
    DioProvider.of(ApiCore.faleConoscoMeus).request(verb: Verb.get, pathParam: fconId),
    FaleConoscoModel.fromJson,
  );

  @override
  Future<Result<FaleConoscoEnvioModel>> enviar(FaleConoscoBodyModel body) => _um(
    DioProvider.of(ApiCore.faleConosco).request(verb: Verb.post, body: body.toJson()),
    FaleConoscoEnvioModel.fromJson,
  );

  @override
  Future<Result<void>> responder({required int fconId, required String texto}) => _um(
    DioProvider.of(ApiCore.faleConoscoInteracaoSolicitante)
        .request(verb: Verb.post, body: {'fconId': fconId, 'fcinTexto': texto}),
    (_) {},
  );

  @override
  Future<Result<List<ConfiguracaoModel>>> configuracoes() =>
      _lista(DioProvider.of(ApiCore.configuracao).request(verb: Verb.get), ConfiguracaoModel.fromJson);

  @override
  Future<Result<List<ConfiguracaoItemModel>>> itens(int confId) => _lista(
    DioProvider.of(ApiCore.configuracaoItem).request(verb: Verb.get, pathParam: confId),
    ConfiguracaoItemModel.fromJson,
  );

  Future<Result<T>> _um<T>(Future<Result<dynamic>> request, T Function(Map<String, dynamic>) fromJson) =>
      _converter(request, (value) {
        if (value is! Map) return null;
        return Result.ok(fromJson(Map<String, dynamic>.from(value)));
      });

  Future<Result<List<T>>> _lista<T>(Future<Result<dynamic>> request, T Function(Map<String, dynamic>) fromJson) =>
      _converter(request, (value) {
        if (value is! List) return null;
        return Result.ok([
          for (final item in value)
            if (item is Map)
              fromJson(Map<String, dynamic>.from(item))
            else
              throw const FormatException(kFormatoInvalido),
        ]);
      });

  /// Converte a resposta com [converter] (nulo = fora do formato esperado) e trata os erros.
  Future<Result<T>> _converter<T>(Future<Result<dynamic>> request, Result<T>? Function(Object? value) converter) async {
    try {
      final response = await request;
      switch (response) {
        case Ok(value: final value):
          return converter(value) ?? Result.error(HandledException(message: 'respostaApiInvalida'));
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

  /// Resposta da API fora do formato esperado.
  static const kFormatoInvalido = 'formatoFaleConoscoInvalido';
}
