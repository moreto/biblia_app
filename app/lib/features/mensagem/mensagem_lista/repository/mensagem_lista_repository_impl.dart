import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/mensagem/mensagem_recebida_model.dart';
import 'mensagem_lista_repository.dart';

class MensagemListaRepositoryImpl implements MensagemListaRepository {
  @override
  Future<Result<List<MensagemRecebidaModel>>> recebidas() async {
    try {
      final response = await DioProvider.of(ApiCore.mensagemRecebidas).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) throw const FormatException(kFormatoInvalido);
                  return MensagemRecebidaModel.fromJson(Map<String, dynamic>.from(item));
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
  Future<Result<Map<String, dynamic>>> atualizar({required int musuId, bool? lida, bool? arquivada}) async {
    try {
      final response = await DioProvider.of(ApiCore.mensagemUsuario)
          .request(verb: Verb.put, body: {'musuId': musuId, 'musuLida': lida, 'musuArquivada': arquivada});
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(Map<String, dynamic>.from(value));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  /// Resposta da API fora do formato esperado.
  static const kFormatoInvalido = 'formatoMensagemInvalido';
}
