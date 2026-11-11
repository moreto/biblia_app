import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/versiculo_indicado_model.dart';
import 'versiculo_indicado_repository.dart';

class VersiculoIndicadoRepositoryImpl implements VersiculoIndicadoRepository {
  @override
  Future<Result<List<VersiculoIndicadoModel>>> recebidas() async {
    try {
      final response = await DioProvider.of(ApiCore.versiculoIndicacaoRecebidas).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) throw const FormatException(kFormatoInvalido);
                  return VersiculoIndicadoModel.fromJson(Map<String, dynamic>.from(item));
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

  /// Resposta fora do formato (chave já existente na API).
  static const kFormatoInvalido = 'formatoIndicacaoInvalido';
}
