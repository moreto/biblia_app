import 'package:commons/commons.dart';

import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';

abstract class ComunidadeListaRepository {
  /// Estados (`GET /v1/estado`).
  Future<Result<List<EstadoModel>>> estados();

  /// Municípios do estado (`GET /v1/municipio/:estaId`).
  Future<Result<List<MunicipioModel>>> municipios(int estaId);

  /// Comunidades de todos os usuários com endereço no estado e, se informado, no município
  /// (`GET /v1/comunidade?estaId=&muniId=`).
  Future<Result<List<ComunidadeLocalModel>>> comunidades({required int estaId, int? muniId});
}
