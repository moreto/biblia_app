import 'package:commons/commons.dart';

import '../../../../../data/model/versiculo/versiculo_reacao_model.dart';

abstract class VersiculoReacaoRepository {
  /// Reações de todos os usuários ao versículo (`GET /v1/versiculo-reacao/:versId`).
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId);

  /// Grava uma reação do usuário do token (`POST /v1/versiculo-reacao`).
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao);

  /// Atualiza uma reação do usuário do token pelo `vreaId` (`PUT /v1/versiculo-reacao`).
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao);
}
