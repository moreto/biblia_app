import 'package:commons/commons.dart';

import '../../../../data/model/mensagem/mensagem_recebida_model.dart';

abstract class MensagemListaRepository {
  /// Mensagens recebidas pelo usuário logado, mais recentes primeiro (`GET /v1/mensagem-usuario/recebidas`).
  Future<Result<List<MensagemRecebidaModel>>> recebidas();

  /// Atualiza a situação da mensagem para o destinatário (`PUT /v1/mensagem-usuario`): [lida] e/ou [arquivada]
  /// (nulos mantêm o valor). Devolve o registro gravado (só os campos de `mensagem_usuario`).
  Future<Result<Map<String, dynamic>>> atualizar({required int musuId, bool? lida, bool? arquivada});
}
