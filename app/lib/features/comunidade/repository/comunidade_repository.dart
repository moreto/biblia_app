import 'package:commons/commons.dart';

import '../../../data/model/comunidade/comunidade_denominacao_model.dart';
import '../../../data/model/comunidade/comunidade_model.dart';
import '../../../data/model/comunidade/comunidade_tipo_model.dart';

abstract class ComunidadeRepository {
  /// Comunidades cadastradas pelo usuário (`GET /v1/comunidade/usuario/:usuaId`).
  Future<Result<List<ComunidadeModel>>> comunidadesDoUsuario(int usuaId);

  /// Tipos de comunidade (`GET /v1/comunidade-tipo`).
  Future<Result<List<ComunidadeTipoModel>>> tipos();

  /// Denominações (`GET /v1/comunidade-denominacao`).
  Future<Result<List<ComunidadeDenominacaoModel>>> denominacoes();

  /// Inclui a comunidade (`POST /v1/comunidade`); a API grava o usuário do token.
  Future<Result<ComunidadeModel>> incluir(ComunidadeModel comunidade);

  /// Altera a comunidade pelo `comuId` (`PUT /v1/comunidade`).
  Future<Result<ComunidadeModel>> alterar(ComunidadeModel comunidade);

  /// Exclui a comunidade (`DELETE /v1/comunidade/:comuId`).
  Future<Result<void>> excluir(int comuId);
}
