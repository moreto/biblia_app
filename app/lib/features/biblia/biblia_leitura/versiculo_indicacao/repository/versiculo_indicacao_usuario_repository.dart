import 'package:commons/commons.dart';

import '../../../../../data/model/biblia/versiculo_indicacao_usuario_model.dart';
import '../../../../../data/model/usuario/usuario_resumo_model.dart';

/// Acesso aos usuários que recebem uma indicação de versículo (`/v1/versiculo-indicacao-usuario`) e à busca de
/// usuários para escolher os destinatários (`/v1/usuario/busca`).
abstract class VersiculoIndicacaoUsuarioRepository {
  /// Usuários indicados da indicação [vindId] do usuário do token (`GET /v1/versiculo-indicacao-usuario/:vindId`).
  Future<Result<List<VersiculoIndicacaoUsuarioModel>>> usuarios(int vindId);

  /// Inclui o usuário [usuaId] como destinatário da indicação [vindId] (`POST /v1/versiculo-indicacao-usuario`).
  Future<Result<VersiculoIndicacaoUsuarioModel>> incluir({required int vindId, required int usuaId});

  /// Troca o destinatário do registro [viusId] (`PUT /v1/versiculo-indicacao-usuario`).
  Future<Result<VersiculoIndicacaoUsuarioModel>> alterar({
    required int viusId,
    required int vindId,
    required int usuaId,
  });

  /// Remove o destinatário [viusId] (`DELETE /v1/versiculo-indicacao-usuario/:viusId`).
  Future<Result<void>> excluir(int viusId);

  /// Usuários ativos, exceto o do token, por nome de usuário ou nome completo (`GET /v1/usuario/busca?texto=`).
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto);
}
