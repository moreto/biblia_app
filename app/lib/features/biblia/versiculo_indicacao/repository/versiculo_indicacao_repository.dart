import 'package:commons/commons.dart';

import '../../../../data/model/biblia/versiculo_indicacao_model.dart';

/// Acesso às indicações de versículo (`/v1/versiculo-indicacao`).
abstract class VersiculoIndicacaoRepository {
  /// Indicações de todos os usuários ao versículo (`GET /v1/versiculo-indicacao/:versId`).
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoes(int versId);

  /// Indicações do usuário do token aos versículos do capítulo, a mais recente de cada versículo
  /// (`GET /v1/versiculo-indicacao/capitulo/:versaId/:livrId/:capiNumero`).
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoesCapitulo(int versaId, int livrId, int capiNumero);

  /// Grava uma indicação do usuário do token (`POST /v1/versiculo-indicacao`).
  Future<Result<VersiculoIndicacaoModel>> incluir(VersiculoIndicacaoModel indicacao);

  /// Atualiza uma indicação do usuário do token pelo `vindId` (`PUT /v1/versiculo-indicacao`).
  Future<Result<VersiculoIndicacaoModel>> alterar(VersiculoIndicacaoModel indicacao);

  /// Remove uma indicação do usuário do token (`DELETE /v1/versiculo-indicacao/:vindId`).
  Future<Result<void>> excluir(int vindId);
}
