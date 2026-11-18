import 'package:commons/commons.dart';

import '../../../../data/model/leitura/leitura_model.dart';

abstract class GrupoLeituraRepository {
  /// Grupos de que o usuário do token é dono ou participante, com `leitDono` (`GET /v1/leitura`).
  Future<Result<List<LeituraModel>>> grupos();

  /// Cria o grupo; o dono é o usuário do token (`POST /v1/leitura`). 403 `consentimentoNecessario` sem o aceite de
  /// dados religiosos.
  Future<Result<LeituraModel>> incluir(LeituraModel grupo);

  /// Altera nome e descrição pelo `leitId` (`PUT /v1/leitura`); 404 se o grupo não for do usuário do token.
  Future<Result<LeituraModel>> alterar(LeituraModel grupo);

  /// Exclui o grupo (`DELETE /v1/leitura/:leitId`); 404 se não for do usuário do token.
  Future<Result<void>> excluir(int leitId);
}
