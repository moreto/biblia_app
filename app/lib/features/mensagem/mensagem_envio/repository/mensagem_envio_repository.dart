import 'package:commons/commons.dart';

import '../../../../data/model/mensagem/mensagem_tipo_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';

abstract class MensagemEnvioRepository {
  /// Tipos de mensagem, inclusive o de sistema (`GET /v1/mensagem-tipo`).
  Future<Result<List<MensagemTipoModel>>> tipos();

  /// Usuários ativos cujo nome ou nome de usuário contém [texto], exceto o logado (`GET /v1/usuario/busca?texto=`).
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto);

  /// Grava a mensagem (autor = usuário do token) e devolve o `mensId` (`POST /v1/mensagem`).
  Future<Result<int>> gravarMensagem({required int mtipId, required String titulo, required String texto});

  /// Inclui o destinatário [usuaId] na mensagem [mensId] (`POST /v1/mensagem-usuario`).
  Future<Result<void>> incluirDestinatario({required int mensId, required int usuaId});
}
