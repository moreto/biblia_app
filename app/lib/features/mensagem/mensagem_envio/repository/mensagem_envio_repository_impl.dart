import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/json_reader.dart';
import '../../../../data/model/mensagem/mensagem_tipo_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import 'mensagem_envio_repository.dart';

class MensagemEnvioRepositoryImpl implements MensagemEnvioRepository {
  @override
  Future<Result<List<MensagemTipoModel>>> tipos() =>
      _lista(DioProvider.of(ApiCore.mensagemTipo).request(verb: Verb.get), MensagemTipoModel.fromJson);

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) => _lista(
    DioProvider.of(ApiCore.usuarioBusca).request(verb: Verb.get, queryParam: {'texto': texto}),
    UsuarioResumoModel.fromJson,
  );

  @override
  Future<Result<int>> gravarMensagem({required int mtipId, required String titulo, required String texto}) async {
    try {
      final response = await DioProvider.of(ApiCore.mensagem)
          .request(verb: Verb.post, body: {'mtipId': mtipId, 'mensTitulo': titulo, 'mensTexto': texto});
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(JsonReader.inteiro(Map<String, dynamic>.from(value), 'mensId', 'mens_id'));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'respostaApiInvalida'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  @override
  Future<Result<void>> incluirDestinatario({required int mensId, required int usuaId}) async {
    try {
      final response = await DioProvider.of(ApiCore.mensagemUsuario)
          .request(verb: Verb.post, body: {'mensId': mensId, 'usuaId': usuaId});
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

  static const kFormatoInvalido = 'formatoMensagemInvalido';
}
