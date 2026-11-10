import 'package:commons/commons.dart';

import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../data/model/localidade/estado_model.dart';
import '../../../../data/model/localidade/municipio_model.dart';

abstract class ComunidadeEnderecoRepository {
  /// Endereços da comunidade, com município e UF (`GET /v1/comunidade-endereco/:comuId`).
  Future<Result<List<ComunidadeEnderecoModel>>> enderecos(int comuId);

  /// Estados (`GET /v1/estado`).
  Future<Result<List<EstadoModel>>> estados();

  /// Municípios do estado (`GET /v1/municipio/:estaId`).
  Future<Result<List<MunicipioModel>>> municipios(int estaId);

  /// Inclui o endereço (`POST /v1/comunidade-endereco`).
  Future<Result<ComunidadeEnderecoModel>> incluir(ComunidadeEnderecoModel endereco);

  /// Altera o endereço pelo `cendId` (`PUT /v1/comunidade-endereco`).
  Future<Result<ComunidadeEnderecoModel>> alterar(ComunidadeEnderecoModel endereco);

  /// Exclui o endereço (`DELETE /v1/comunidade-endereco/:cendId`).
  Future<Result<void>> excluir(int cendId);
}
