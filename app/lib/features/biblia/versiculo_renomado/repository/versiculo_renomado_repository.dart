import 'package:commons/commons.dart';

import '../../../../data/model/biblia/versiculo_renomado_model.dart';

abstract class VersiculoRenomadoRepository {
  /// Versículos do renomado na versão (`GET /v1/versiculo-renomado/:renoId/:versaId`).
  Future<Result<List<VersiculoRenomadoModel>>> versiculos(int renoId, int versaId);
}
