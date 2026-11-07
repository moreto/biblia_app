import 'package:commons/commons.dart';

import '../../../../../data/model/versiculo/versiculo_model.dart';

abstract class VersiculoRepository {
  /// Um versículo sorteado pela API (`GET /v1/versiculo/aleatorio`); cada chamada faz um novo sorteio.
  Future<Result<VersiculoModel>> aleatorio();
}
