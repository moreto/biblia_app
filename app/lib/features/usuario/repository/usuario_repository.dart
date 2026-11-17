import 'package:commons/commons.dart';

import '../../../data/model/usuario/usuario_configuracao_model.dart';
import '../../../data/model/usuario/usuario_detalhe_model.dart';

abstract class UsuarioRepository {
  /// Dados do usuário do token: e-mail, situação, nome completo e nome de usuário
  /// (`GET /v1/usuario/usuario-detalhe-by-id`).
  Future<Result<UsuarioDetalheModel>> detalhe();

  /// Altera o nome completo e o nome de usuário e devolve o detalhe atualizado (`PUT /v1/usuario/usuario-detalhe`);
  /// 409 `nomeUsuarioDuplicado` se o nome de usuário for de outro usuário.
  Future<Result<UsuarioDetalheModel>> alterarDetalhe(UsuarioDetalheBodyModel body);

  /// Troca a senha (`PUT /v1/acesso/senha`), com as duas senhas já criptografadas; 401 `senhaAtualInvalida` e 400
  /// `novaSenhaIgualAtual`.
  Future<Result<void>> alterarSenha({required String senhaAtual, required String novaSenha});

  /// Configuração do usuário do token (`GET /v1/usuario-configuracao`); 404 `registroNaoEncontrado` se não houver.
  Future<Result<UsuarioConfiguracaoModel>> configuracao();

  /// Grava a primeira configuração do usuário (`POST /v1/usuario-configuracao`); 409
  /// `usuarioConfiguracaoDuplicada` se ele já tiver uma.
  Future<Result<UsuarioConfiguracaoModel>> incluirConfiguracao(UsuarioConfiguracaoModel configuracao);

  /// Altera a configuração [UsuarioConfiguracaoModel.uconId] do usuário (`PUT /v1/usuario-configuracao`).
  Future<Result<UsuarioConfiguracaoModel>> alterarConfiguracao(UsuarioConfiguracaoModel configuracao);
}
