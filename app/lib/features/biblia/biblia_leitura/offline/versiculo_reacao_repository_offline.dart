import 'package:commons/commons.dart';

import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../../../dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import 'falha_api.dart';
import 'offline_base.dart';

/// [VersiculoReacaoRepository] que marca versículos como lidos sem conexão, decorando o da API ([api]).
///
/// Vale para versículos cujo texto está no aparelho (capítulo aberto na leitura ou versão baixada), porque a
/// marcação precisa saber o capítulo para entrar no progresso. Os demais (ex.: o versículo do dia, nunca aberto na
/// leitura) e o uso sem usuário logado vão direto à API.
///
/// - [reacoes]: as da API, com a do usuário trocada pela do aparelho (que tem as alterações pendentes); sem
///   conexão, só a do aparelho;
/// - [incluir] e [alterar]: gravam no aparelho e pedem a sincronização. O comentário só é enviado se mudou.
class VersiculoReacaoRepositoryOffline extends OfflineBase implements VersiculoReacaoRepository {
  VersiculoReacaoRepositoryOffline({
    required this.api,
    required super.store,
    required super.conectividade,
    required super.sincronizacao,
    super.usuarioLogado,
    super.agora,
  });

  final VersiculoReacaoRepository api;

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId) async {
    final usuaId = usuarioLogado();
    final coordenada = usuaId == null ? null : await local(() => store.coordenada(versId));
    if (usuaId == null || coordenada == null) return api.reacoes(versId);

    final inicio = agoraMs;
    final result = await remoto(() => api.reacoes(versId));
    final List<VersiculoReacaoModel> base;
    switch (result) {
      case Ok<List<VersiculoReacaoModel>>(value: final lista):
        base = lista;
        VersiculoReacaoModel? minha;
        for (final r in lista) {
          if (r.usuaId == usuaId && (minha == null || (r.vreaId ?? 0) > (minha.vreaId ?? 0))) minha = r;
        }
        await local(
          () => store.mesclarReacoesServidor(usuaId, coordenada, [?minha], inicio: inicio, apenasVersId: versId),
        );
      case Error<List<VersiculoReacaoModel>>(error: final error):
        if (!apiInacessivel(error)) return result;
        base = const [];
    }

    final minha = await local(() => store.reacao(usuaId, versId));
    return Result.ok([...base.where((r) => r.usuaId != usuaId), ?minha?.toModel(usuaId)]);
  }

  @override
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao) =>
      _gravar(reacao, () => api.incluir(reacao));

  @override
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao) =>
      _gravar(reacao, () => api.alterar(reacao));

  Future<Result<VersiculoReacaoModel>> _gravar(
    VersiculoReacaoModel reacao,
    Future<Result<VersiculoReacaoModel>> Function() direto,
  ) async {
    final usuaId = usuarioLogado();
    final coordenada = usuaId == null ? null : await local(() => store.coordenada(reacao.versId));
    if (usuaId == null || coordenada == null) return direto();

    final gravada = await local(() async {
      final atual = await store.reacao(usuaId, reacao.versId);
      final comentarioAlterado = (reacao.vreaComentario ?? '') != (atual?.comentario ?? '');
      return store.gravarReacao(
        usuaId,
        reacao.versId,
        coordenada,
        lido: reacao.vreaLido,
        comentario: reacao.vreaComentario,
        comentarioAlterado: comentarioAlterado,
      );
    });
    if (gravada == null) return direto();

    sincronizacao.agendar();
    return Result.ok(gravada.toModel(usuaId));
  }
}
