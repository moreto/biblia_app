import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import '../../../data/model/fale_conosco/fale_conosco_atendimento_model.dart';
import 'fale_conosco_atendimento_repository.dart';

class FaleConoscoAtendimentoRepositoryImpl implements FaleConoscoAtendimentoRepository {
  @override
  Future<Result<List<FaleConoscoAtendimentoModel>>> fila(FaleConoscoAtendimentoFiltroModel filtro) => _lista(
    DioProvider.of(ApiCore.faleConosco).request(verb: Verb.get, queryParam: filtro.vazio ? null : filtro.toQuery()),
    FaleConoscoAtendimentoModel.fromJson,
  );

  @override
  Future<Result<FaleConoscoAtendimentoModel>> chamado(int fconId) => _um(
    DioProvider.of(ApiCore.faleConosco).request(verb: Verb.get, pathParam: fconId),
    FaleConoscoAtendimentoModel.fromJson,
  );

  @override
  Future<Result<List<FaleConoscoAtendimentoInteracaoModel>>> interacoes(int fconId) => _lista(
    DioProvider.of(ApiCore.faleConoscoInteracao).request(verb: Verb.get, pathParam: fconId),
    FaleConoscoAtendimentoInteracaoModel.fromJson,
  );

  @override
  Future<Result<void>> responder(FaleConoscoAtendimentoInteracaoBodyModel body) =>
      _um(DioProvider.of(ApiCore.faleConoscoInteracao).request(verb: Verb.post, body: body.toJson()), (_) {});

  @override
  Future<Result<FaleConoscoAtendimentoModel>> atualizar(FaleConoscoAtendimentoBodyModel body) => _um(
    DioProvider.of(ApiCore.faleConosco).request(verb: Verb.put, body: body.toJson()),
    FaleConoscoAtendimentoModel.fromJson,
  );

  @override
  Future<Result<void>> excluir(int fconId) =>
      _um(DioProvider.of(ApiCore.faleConosco).request(verb: Verb.delete, pathParam: fconId), (_) {});

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

  /// Resposta da API fora do formato esperado (mesma chave da tela do solicitante).
  static const kFormatoInvalido = 'formatoFaleConoscoInvalido';
}
