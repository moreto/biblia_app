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
}
