import 'package:commons/commons.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../data/model/comunidade/comunidade_humanograma_model.dart';
import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../../data/model/comunidade/comunidade_usuario_model.dart';
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

  /// Endereços da comunidade (`GET /v1/comunidade-endereco/:comuId`).
  Future<Result<List<ComunidadeEnderecoModel>>> enderecos(int comuId);

  /// Contatos da comunidade (`GET /v1/comunidade-contato/:comuId`).
  Future<Result<List<ComunidadeContatoModel>>> contatos(int comuId);

  /// Humanograma (pessoas e cargos) da comunidade (`GET /v1/comunidade-humanograma-dto/:comuId`).
  Future<Result<List<ComunidadeHumanogramaModel>>> humanograma(int comuId);

  /// Usuários vinculados à comunidade (`GET /v1/comunidade-usuario/:comuId`); usado só para contar os ativos.
  Future<Result<List<ComunidadeUsuarioModel>>> usuarios(int comuId);
}
