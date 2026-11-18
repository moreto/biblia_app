import 'package:commons/commons.dart';

import '../../../../data/model/leitura/leitura_agenda_model.dart';

abstract class GrupoLeituraAgendaRepository {
  /// Itens da agenda do grupo, por data e hora, os sem data por último (`GET /v1/leitura-agenda/:leitId`).
  Future<Result<List<LeituraAgendaModel>>> agenda(int leitId);

  /// Inclui o item (`POST /v1/leitura-agenda`); 404 se o grupo não for do usuário do token.
  Future<Result<LeituraAgendaModel>> incluir(LeituraAgendaModel item);

  /// Altera o item pelo `lageId` (`PUT /v1/leitura-agenda`); 404 se o grupo não for do usuário do token.
  Future<Result<LeituraAgendaModel>> alterar(LeituraAgendaModel item);

  /// Exclui o item e as atividades dele (`DELETE /v1/leitura-agenda/:lageId`).
  Future<Result<void>> excluir(int lageId);
}
