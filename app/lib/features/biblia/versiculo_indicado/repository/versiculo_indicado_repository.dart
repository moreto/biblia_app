import 'package:commons/commons.dart';

import '../../../../data/model/biblia/versiculo_indicado_model.dart';

abstract class VersiculoIndicadoRepository {
  /// Indicações de versículo recebidas pelo usuário logado, mais recentes primeiro
  /// (`GET /v1/versiculo-indicacao-usuario/recebidas`).
  Future<Result<List<VersiculoIndicadoModel>>> recebidas();
}
