import 'package:commons/commons.dart';

import '../../../../../../data/model/funcionalidade/funcionalidade_model.dart';

abstract class FuncionalidadeRepository {
  /// Todas as funcionalidades do app, ativas e inativas, na ordem de cadastro (`GET /v1/funcionalidade`).
  Future<Result<List<FuncionalidadeModel>>> listar();
}
