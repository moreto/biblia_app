import 'package:commons/commons.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/leitura/leitura_agenda_atividade_model.dart';

abstract class GrupoLeituraAtividadeRepository {
  /// Atividades do item da agenda, por `laatSeq` (`GET /v1/leitura-agenda-atividade/:lageId`).
  Future<Result<List<LeituraAgendaAtividadeModel>>> atividades(int lageId);

  /// Livros da Bíblia, para a escolha do livro da atividade (`GET /v1/livro`).
  Future<Result<List<LivroModel>>> livros();

  /// Inclui a atividade (`POST /v1/leitura-agenda-atividade`); 404 se o grupo não for do usuário do token ou se o
  /// livro, a música ou a oração não existirem.
  Future<Result<LeituraAgendaAtividadeModel>> incluir(LeituraAgendaAtividadeModel atividade);

  /// Altera a atividade pelo `laatId` (`PUT /v1/leitura-agenda-atividade`).
  Future<Result<LeituraAgendaAtividadeModel>> alterar(LeituraAgendaAtividadeModel atividade);

  /// Exclui a atividade (`DELETE /v1/leitura-agenda-atividade/:laatId`).
  Future<Result<void>> excluir(int laatId);
}
