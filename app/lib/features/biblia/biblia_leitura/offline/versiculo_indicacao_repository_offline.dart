import 'dart:convert';

import 'package:commons/commons.dart';

import '../../../../data/local/leitura_local_store.dart';
import '../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import 'falha_api.dart';
import 'offline_base.dart';

/// [VersiculoIndicacaoRepository] que indica versículos sem conexão, decorando o da API ([api]).
///
/// Como na marcação de lido, vale para versículos com o texto no aparelho; os demais vão direto à API.
///
/// - consultas: as da API, com a indicação do usuário trocada pela do aparelho; sem conexão, as últimas guardadas;
/// - [incluir], [alterar] e [excluir]: gravam no aparelho e pedem a sincronização.
///
/// Indicação feita offline ainda não tem `vindId` da API: o app recebe o id provisório `-versId` (negativo), que
/// [alterar] e [excluir] reconhecem. Os destinatários dependem do `vindId` real, então só podem ser escolhidos
/// depois da sincronização.
class VersiculoIndicacaoRepositoryOffline extends OfflineBase implements VersiculoIndicacaoRepository {
  VersiculoIndicacaoRepositoryOffline({
    required this.api,
    required super.store,
    required super.conectividade,
    required super.sincronizacao,
    super.usuarioLogado,
    super.agora,
  });

  final VersiculoIndicacaoRepository api;

  static Map<String, dynamic> _toCache(VersiculoIndicacaoModel i) => {
    'vindId': i.vindId,
    'versId': i.versId,
    'usuaId': i.usuaId,
    'vindComentario': i.vindComentario,
  };

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoes(int versId) async {
    final usuaId = usuarioLogado();
    final coordenada = usuaId == null ? null : await local(() => store.coordenada(versId));
    if (usuaId == null || coordenada == null) return api.indicacoes(versId);

    final chave = LeituraLocalStore.chaveIndicacoes(usuaId, versId);
    final inicio = agoraMs;
    final result = await remoto(() => api.indicacoes(versId));
    final List<VersiculoIndicacaoModel> base;
    switch (result) {
      case Ok<List<VersiculoIndicacaoModel>>(value: final lista):
        base = lista;
        await local(() async {
          await store.salvarCache(chave, jsonEncode(lista.map(_toCache).toList()));
          await store.mesclarIndicacoesServidor(
            usuaId,
            coordenada,
            [?_maisRecente(lista.where((i) => i.usuaId == usuaId))],
            inicio: inicio,
            apenasVersId: versId,
          );
        });
      case Error<List<VersiculoIndicacaoModel>>(error: final error):
        if (!apiInacessivel(error)) return result;
        base = await lerLista(chave, VersiculoIndicacaoModel.fromJson) ?? const [];
    }

    final minha = await local(() => store.indicacao(usuaId, versId));
    return Result.ok([
      ...base.where((i) => i.usuaId != usuaId),
      if (minha != null && !minha.excluida) minha.toModel(usuaId),
    ]);
  }

  static VersiculoIndicacaoModel? _maisRecente(Iterable<VersiculoIndicacaoModel> lista) {
    VersiculoIndicacaoModel? maior;
    for (final i in lista) {
      if (maior == null || (i.vindId ?? 0) > (maior.vindId ?? 0)) maior = i;
    }
    return maior;
  }

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoesCapitulo(int versaId, int livrId, int capiNumero) async {
    final usuaId = usuarioLogado();
    if (usuaId == null) return api.indicacoesCapitulo(versaId, livrId, capiNumero);

    final inicio = agoraMs;
    final result = await remoto(() => api.indicacoesCapitulo(versaId, livrId, capiNumero));
    switch (result) {
      case Ok<List<VersiculoIndicacaoModel>>(value: final lista):
        final porVersiculo = <int, VersiculoIndicacaoModel>{};
        for (final i in lista) {
          final atual = porVersiculo[i.versId];
          if (atual == null || (i.vindId ?? 0) > (atual.vindId ?? 0)) porVersiculo[i.versId] = i;
        }
        await local(
          () => store.mesclarIndicacoesServidor(
            usuaId,
            (versaId: versaId, livrId: livrId, capiNumero: capiNumero),
            porVersiculo.values.toList(),
            inicio: inicio,
          ),
        );
      case Error<List<VersiculoIndicacaoModel>>(error: final error):
        if (!apiInacessivel(error)) return result;
    }

    final locais = await local(() => store.indicacoesDoCapitulo(usuaId, versaId, livrId, capiNumero));
    if (locais == null) return result;
    return Result.ok([
      for (final i in locais)
        if (!i.excluida) i.toModel(usuaId),
    ]);
  }

  @override
  Future<Result<VersiculoIndicacaoModel>> incluir(VersiculoIndicacaoModel indicacao) =>
      _gravar(indicacao, () => api.incluir(indicacao));

  @override
  Future<Result<VersiculoIndicacaoModel>> alterar(VersiculoIndicacaoModel indicacao) =>
      _gravar(indicacao, () => api.alterar(indicacao));

  Future<Result<VersiculoIndicacaoModel>> _gravar(
    VersiculoIndicacaoModel indicacao,
    Future<Result<VersiculoIndicacaoModel>> Function() direto,
  ) async {
    final usuaId = usuarioLogado();
    final coordenada = usuaId == null ? null : await local(() => store.coordenada(indicacao.versId));
    if (usuaId == null || coordenada == null) return direto();

    final gravada = await local(
      () => store.gravarIndicacao(usuaId, indicacao.versId, coordenada, comentario: indicacao.vindComentario),
    );
    if (gravada == null) return direto();

    sincronizacao.agendar();
    return Result.ok(gravada.toModel(usuaId));
  }

  @override
  Future<Result<void>> excluir(int vindId) async {
    final usuaId = usuarioLogado();
    final atual = usuaId == null
        ? null
        : await local(() => vindId < 0 ? store.indicacao(usuaId, -vindId) : store.indicacaoPorVindId(usuaId, vindId));
    if (usuaId == null || atual == null) {
      return vindId < 0 ? const Result.ok(null) : api.excluir(vindId);
    }

    final gravada = await local(() => store.gravarIndicacao(usuaId, atual.versId, atual.coordenada, excluida: true));
    if (gravada == null) return vindId < 0 ? const Result.ok(null) : api.excluir(vindId);

    sincronizacao.agendar();
    return const Result.ok(null);
  }
}
