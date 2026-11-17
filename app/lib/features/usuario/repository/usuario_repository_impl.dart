import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/usuario/usuario_configuracao_model.dart';
import '../../../data/model/usuario/usuario_detalhe_model.dart';
import 'usuario_repository.dart';

class UsuarioRepositoryImpl implements UsuarioRepository {
  @override
  Future<Result<UsuarioDetalheModel>> detalhe() =>
      _mapa(DioProvider.of(ApiCore.usuarioDetalhe).request(verb: Verb.get), UsuarioDetalheModel.fromJson);

  @override
  Future<Result<UsuarioDetalheModel>> alterarDetalhe(UsuarioDetalheBodyModel body) => _mapa(
    DioProvider.of(ApiCore.usuarioDetalheAlterar).request(verb: Verb.put, body: body.toJson()),
    UsuarioDetalheModel.fromJson,
  );

  /// A API responde 200 `{ code: 0, message: "senhaAlterada" }`; o corpo não é usado.
  @override
  Future<Result<void>> alterarSenha({required String senhaAtual, required String novaSenha}) => _mapa(
    DioProvider.of(ApiCore.acessoSenha)
        .request(verb: Verb.put, body: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    (_) {},
  );

  @override
  Future<Result<UsuarioConfiguracaoModel>> configuracao() =>
      _mapa(DioProvider.of(ApiCore.usuarioConfiguracao).request(verb: Verb.get), UsuarioConfiguracaoModel.fromJson);

  @override
  Future<Result<UsuarioConfiguracaoModel>> incluirConfiguracao(UsuarioConfiguracaoModel configuracao) => _mapa(
    DioProvider.of(ApiCore.usuarioConfiguracao).request(verb: Verb.post, body: configuracao.toJson()),
    UsuarioConfiguracaoModel.fromJson,
  );

  @override
  Future<Result<UsuarioConfiguracaoModel>> alterarConfiguracao(UsuarioConfiguracaoModel configuracao) => _mapa(
    DioProvider.of(ApiCore.usuarioConfiguracao).request(verb: Verb.put, body: configuracao.toJson()),
    UsuarioConfiguracaoModel.fromJson,
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
  static const kFormatoInvalido = 'formatoUsuarioInvalido';
}
