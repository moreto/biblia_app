import 'package:commons/commons.dart';

import '../../../data/model/biblia/capitulo_lido_model.dart';

/// Acesso ao histórico de leitura do usuário do token.
abstract class HistoricoLeituraRepository {
  /// Capítulos com ao menos um versículo lido na versão (`GET /v1/versiculo-reacao/lidos/:versaId`), com o total de
  /// versículos, os lidos e a data da última leitura de cada um.
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId);
}
