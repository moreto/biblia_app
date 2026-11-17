import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/json_reader.dart';
import '../../../../data/model/usuario/usuario_consentimento_model.dart';
import 'usuario_consentimento_repository.dart';

class UsuarioConsentimentoRepositoryImpl implements UsuarioConsentimentoRepository {
  @override
  Future<Result<UsuarioConsentimentoListaModel>> listar() => _mapa(
    DioProvider.of(ApiCore.usuarioConsentimento).request(verb: Verb.get),
    UsuarioConsentimentoListaModel.fromJson,
  );

  @override
  Future<Result<UsuarioConsentimentoModel>> aceitar(UsuarioConsentimentoBodyModel body) => _mapa(
    DioProvider.of(ApiCore.usuarioConsentimento).request(verb: Verb.post, body: body.toJson()),
    UsuarioConsentimentoModel.fromJson,
  );

  /// A finalidade vai codificada no path.
  @override
  Future<Result<int>> revogar(String finalidade) => _mapa(
    DioProvider.of(ApiCore.usuarioConsentimento).request(verb: Verb.delete, pathParam: Uri.encodeComponent(finalidade)),
    (json) => JsonReader.inteiroOpcional(json, 'revogados', 'revogados') ?? 0,
  );

  Future<Result<T>> _mapa<T>(Future<Result<dynamic>> request, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await request;
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(fromJson(Map<String, dynamic>.from(value)));
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
  static const kFormatoInvalido = 'formatoConsentimentoInvalido';
}
