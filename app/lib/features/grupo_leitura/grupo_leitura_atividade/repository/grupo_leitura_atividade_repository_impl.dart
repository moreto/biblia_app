import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/leitura/leitura_agenda_atividade_model.dart';
import '../../grupo_leitura/repository/leitura_resposta.dart';
import 'grupo_leitura_atividade_repository.dart';

class GrupoLeituraAtividadeRepositoryImpl implements GrupoLeituraAtividadeRepository {
  @override
  Future<Result<List<LeituraAgendaAtividadeModel>>> atividades(int lageId) => LeituraResposta.lista(
    DioProvider.of(ApiCore.leituraAgendaAtividade).request(verb: Verb.get, pathParam: lageId),
    LeituraAgendaAtividadeModel.fromJson,
  );

  @override
  Future<Result<List<LivroModel>>> livros() =>
      LeituraResposta.lista(DioProvider.of(ApiCore.livro).request(verb: Verb.get), LivroModel.fromJson);

  @override
  Future<Result<LeituraAgendaAtividadeModel>> incluir(LeituraAgendaAtividadeModel atividade) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leituraAgendaAtividade).request(verb: Verb.post, body: atividade.toJson()),
    LeituraAgendaAtividadeModel.fromJson,
  );

  @override
  Future<Result<LeituraAgendaAtividadeModel>> alterar(LeituraAgendaAtividadeModel atividade) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leituraAgendaAtividade).request(verb: Verb.put, body: atividade.toJson()),
    LeituraAgendaAtividadeModel.fromJson,
  );

  @override
  Future<Result<void>> excluir(int laatId) => LeituraResposta.excluir(
    DioProvider.of(ApiCore.leituraAgendaAtividade).request(verb: Verb.delete, pathParam: laatId),
  );
}
