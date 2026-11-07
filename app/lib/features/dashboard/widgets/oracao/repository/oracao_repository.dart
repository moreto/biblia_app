import 'package:commons/commons.dart';

import '../../../../../data/model/oracao/oracao_model.dart';

abstract class OracaoRepository {
  /// Uma oração sorteada pela API (`GET /v1/oracao/aleatoria`); cada chamada faz um novo sorteio.
  Future<Result<OracaoModel>> aleatoria();
}
