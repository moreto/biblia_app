import 'package:commons/commons.dart';

import '../../../../data/model/leitura/leitura_participante_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';

abstract class GrupoLeituraParticipanteRepository {
  /// Participantes do grupo, com nome e nome de usuário (`GET /v1/leitura-participante/:leitId`).
  Future<Result<List<LeituraParticipanteModel>>> participantes(int leitId);

  /// Usuários ativos cujo nome ou nome de usuário contém [texto], exceto o logado (`GET /v1/usuario/busca?texto=`).
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto);

  /// Inclui o participante (`POST /v1/leitura-participante`); 409 `leituraParticipanteDuplicado` se ele já
  /// participar do grupo.
  Future<Result<LeituraParticipanteModel>> incluir(LeituraParticipanteModel participante);

  /// Remove o participante (`DELETE /v1/leitura-participante/:lparId`).
  Future<Result<void>> excluir(int lparId);
}
