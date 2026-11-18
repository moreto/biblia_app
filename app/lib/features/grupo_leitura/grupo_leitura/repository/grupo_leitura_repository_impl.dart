import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/leitura/leitura_model.dart';
import 'grupo_leitura_repository.dart';
import 'leitura_resposta.dart';

class GrupoLeituraRepositoryImpl implements GrupoLeituraRepository {
  @override
  Future<Result<List<LeituraModel>>> grupos() =>
      LeituraResposta.lista(DioProvider.of(ApiCore.leitura).request(verb: Verb.get), LeituraModel.fromJson);

  @override
  Future<Result<LeituraModel>> incluir(LeituraModel grupo) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leitura).request(verb: Verb.post, body: grupo.toJson()),
    LeituraModel.fromJson,
  );

  @override
  Future<Result<LeituraModel>> alterar(LeituraModel grupo) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leitura).request(verb: Verb.put, body: grupo.toJson()),
    LeituraModel.fromJson,
  );

  @override
  Future<Result<void>> excluir(int leitId) =>
      LeituraResposta.excluir(DioProvider.of(ApiCore.leitura).request(verb: Verb.delete, pathParam: leitId));
}
