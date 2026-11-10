import 'package:commons/commons.dart';

import '../../../../data/model/biblia/renomado_model.dart';

abstract class RenomadoRepository {
  /// Todos os renomados (`GET /v1/renomado`).
  Future<Result<List<RenomadoModel>>> getAll();
}
