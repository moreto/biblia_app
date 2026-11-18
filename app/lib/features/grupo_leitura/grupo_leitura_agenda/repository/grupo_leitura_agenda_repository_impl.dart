import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../grupo_leitura/repository/leitura_resposta.dart';
import 'grupo_leitura_agenda_repository.dart';

class GrupoLeituraAgendaRepositoryImpl implements GrupoLeituraAgendaRepository {
  @override
  Future<Result<List<LeituraAgendaModel>>> agenda(int leitId) => LeituraResposta.lista(
    DioProvider.of(ApiCore.leituraAgenda).request(verb: Verb.get, pathParam: leitId),
    LeituraAgendaModel.fromJson,
  );

  @override
  Future<Result<LeituraAgendaModel>> incluir(LeituraAgendaModel item) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leituraAgenda).request(verb: Verb.post, body: item.toJson()),
    LeituraAgendaModel.fromJson,
  );

  @override
  Future<Result<LeituraAgendaModel>> alterar(LeituraAgendaModel item) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leituraAgenda).request(verb: Verb.put, body: item.toJson()),
    LeituraAgendaModel.fromJson,
  );

  @override
  Future<Result<void>> excluir(int lageId) =>
      LeituraResposta.excluir(DioProvider.of(ApiCore.leituraAgenda).request(verb: Verb.delete, pathParam: lageId));
}
