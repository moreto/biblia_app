import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../offline/leitura_offline_repository.dart';
import '../offline/leitura_sincronizacao.dart';

/// Regras da leitura sem conexão:
/// - [estado] avisa quando muda a conexão, a quantidade de marcações pendentes ou se está sincronizando;
/// - [sincronizar] envia as pendências; sem conexão não faz nada (elas esperam a conexão voltar);
/// - baixar a versão exige conexão (`semConexaoParaBaixar`) e os livros dela (`nenhumLivroDisponivel`); o
///   andamento vai de 0 a 1;
/// - capítulos abertos ficam salvos mesmo sem baixar a versão inteira.
class LeituraOfflineUseCase {
  LeituraOfflineUseCase({required this.leituraOfflineRepository, required this.sincronizacao}) {
    Log.print(super.runtimeType);
  }

  final LeituraOfflineRepository leituraOfflineRepository;
  final LeituraSincronizacao sincronizacao;

  Listenable get estado => sincronizacao;
  bool get online => sincronizacao.online;
  int get pendentes => sincronizacao.pendentes;
  bool get sincronizando => sincronizacao.sincronizando;

  /// Envia as marcações pendentes e devolve quantas ainda faltam.
  Future<Result<int>> sincronizar() async {
    await sincronizacao.sincronizar();
    return Result.ok(sincronizacao.pendentes);
  }

  /// A API recusou alguma marcação desde a última consulta: a tela deve recarregar o progresso.
  bool consumirDescartada() => sincronizacao.consumirDescartada();

  Future<Set<int>> versoesBaixadas() => leituraOfflineRepository.versoesBaixadas();

  Future<Result<void>> baixarVersao(
    VersaoModel versao,
    List<LivroModel> livros, {
    void Function(double andamento)? progresso,
  }) async {
    if (!online) return Result.error(HandledException(message: 'semConexaoParaBaixar'));
    if (livros.isEmpty) return Result.error(HandledException(message: 'nenhumLivroDisponivel'));
    return leituraOfflineRepository.baixarVersao(versao.versaId, [
      for (final livro in livros) livro.livrId,
    ], progresso: progresso == null ? null : (prontos, total) => progresso(total == 0 ? 0 : prontos / total));
  }

  Future<Result<void>> removerVersao(VersaoModel versao) => leituraOfflineRepository.removerVersao(versao.versaId);
}
