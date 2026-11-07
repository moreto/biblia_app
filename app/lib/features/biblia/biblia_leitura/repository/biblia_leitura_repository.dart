import 'package:commons/commons.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';

/// Acesso às APIs de leitura da Bíblia e ao progresso de leitura do usuário.
abstract class BibliaLeituraRepository {
  /// Versões disponíveis (`GET /v1/versao`).
  Future<Result<List<VersaoModel>>> versoes();

  /// Testamentos (`GET /v1/testamento`).
  Future<Result<List<TestamentoModel>>> testamentos();

  /// Livros com testamento e quantidade de capítulos (`GET /v1/livro`).
  Future<Result<List<LivroModel>>> livros();

  /// Capítulos da versão com a quantidade de versículos (`GET /v1/biblia/indice/:versaId`).
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId);

  /// Versículos do capítulo (`GET /v1/biblia/capitulo/:versaId/:livrId/:capiNumero`).
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero);

  /// Capítulos com ao menos um versículo lido pelo usuário do token (`GET /v1/versiculo-reacao/lidos/:versaId`).
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId);

  /// Marca ou desmarca como lidos todos os versículos do capítulo (`PUT /v1/versiculo-reacao/capitulo`).
  /// Devolve o total de versículos do capítulo.
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido});
}
