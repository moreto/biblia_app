import 'package:commons/commons.dart';

import '../../../../data/model/usuario/usuario_consentimento_model.dart';

abstract class UsuarioConsentimentoRepository {
  /// Termos de cada finalidade (versão atual e se está aceito) e o histórico de aceites e revogações do usuário
  /// (`GET /v1/usuario-consentimento`).
  Future<Result<UsuarioConsentimentoListaModel>> listar();

  /// Registra o aceite do termo (`POST /v1/usuario-consentimento`); 400 `dadosInvalidos` se a versão não for a atual.
  Future<Result<UsuarioConsentimentoModel>> aceitar(UsuarioConsentimentoBodyModel body);

  /// Revoga os aceites vigentes da [finalidade] e devolve quantos foram revogados
  /// (`DELETE /v1/usuario-consentimento/:ucnsFinalidade`); 404 `registroNaoEncontrado` se não havia aceite vigente.
  Future<Result<int>> revogar(String finalidade);
}
