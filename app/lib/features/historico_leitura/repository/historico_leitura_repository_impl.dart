import 'package:commons/commons.dart';

import '../../../data/model/biblia/capitulo_lido_model.dart';
import '../../biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'historico_leitura_repository.dart';

/// Histórico de leitura pelo mesmo repository da leitura da Bíblia (o registrado no `locator`, que é o
/// `BibliaLeituraRepositoryOffline`).
///
/// Não chama o `DioProvider` diretamente para manter o comportamento offline da leitura: sem conexão, o histórico
/// vem do cache da tabela `cache` e soma as marcações ainda pendentes no aparelho (veja `files/docs/arquitetura.md`,
/// seção "Leitura offline"). Com conexão, o endpoint é `GET /v1/versiculo-reacao/lidos/:versaId`.
class HistoricoLeituraRepositoryImpl implements HistoricoLeituraRepository {
  HistoricoLeituraRepositoryImpl({required this.leitura});

  final BibliaLeituraRepository leitura;

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async {
    try {
      return await leitura.lidos(versaId);
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
