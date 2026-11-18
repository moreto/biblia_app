import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/model/leitura/leitura_participante_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../../grupo_leitura/repository/leitura_resposta.dart';
import 'grupo_leitura_participante_repository.dart';

class GrupoLeituraParticipanteRepositoryImpl implements GrupoLeituraParticipanteRepository {
  @override
  Future<Result<List<LeituraParticipanteModel>>> participantes(int leitId) => LeituraResposta.lista(
    DioProvider.of(ApiCore.leituraParticipante).request(verb: Verb.get, pathParam: leitId),
    LeituraParticipanteModel.fromJson,
  );

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) => LeituraResposta.lista(
    DioProvider.of(ApiCore.usuarioBusca).request(verb: Verb.get, queryParam: {'texto': texto}),
    UsuarioResumoModel.fromJson,
  );

  @override
  Future<Result<LeituraParticipanteModel>> incluir(LeituraParticipanteModel participante) => LeituraResposta.objeto(
    DioProvider.of(ApiCore.leituraParticipante).request(verb: Verb.post, body: participante.toJson()),
    LeituraParticipanteModel.fromJson,
  );

  @override
  Future<Result<void>> excluir(int lparId) => LeituraResposta.excluir(
    DioProvider.of(ApiCore.leituraParticipante).request(verb: Verb.delete, pathParam: lparId),
  );
}
