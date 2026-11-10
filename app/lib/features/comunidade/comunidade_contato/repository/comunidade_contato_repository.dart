import 'package:commons/commons.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';

abstract class ComunidadeContatoRepository {
  /// Contatos da comunidade (`GET /v1/comunidade-contato/:comuId`).
  Future<Result<List<ComunidadeContatoModel>>> contatos(int comuId);

  /// Inclui o contato (`POST /v1/comunidade-contato`).
  Future<Result<ComunidadeContatoModel>> incluir(ComunidadeContatoModel contato);

  /// Altera o contato pelo `cconId` (`PUT /v1/comunidade-contato`).
  Future<Result<ComunidadeContatoModel>> alterar(ComunidadeContatoModel contato);

  /// Exclui o contato (`DELETE /v1/comunidade-contato/:cconId`).
  Future<Result<void>> excluir(int cconId);
}
