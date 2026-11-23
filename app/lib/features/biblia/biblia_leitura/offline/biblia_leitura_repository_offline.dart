import 'package:commons/commons.dart';

import '../../../../data/local/leitura_local_store.dart';
import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../repository/biblia_leitura_repository.dart';
import 'falha_api.dart';
import 'offline_base.dart';

/// [BibliaLeituraRepository] que funciona sem conexão, decorando o da API ([api]):
/// - versões, testamentos, livros e índice: consulta a API e guarda a resposta; sem resposta, usa a guardada;
/// - capítulo: lê do aparelho se já estiver salvo (aberto antes ou versão baixada); senão busca na API e salva;
/// - progresso (`lidos`) e reações do capítulo: o da API (guardado no aparelho) com as marcações pendentes por cima;
/// - marcar o capítulo grava no aparelho e pede a sincronização. Sem o texto do capítulo no aparelho (ou sem
///   usuário logado), vai direto à API.
class BibliaLeituraRepositoryOffline extends OfflineBase implements BibliaLeituraRepository {
  BibliaLeituraRepositoryOffline({
    required this.api,
    required super.store,
    required super.conectividade,
    required super.sincronizacao,
    super.usuarioLogado,
    super.agora,
  });

  final BibliaLeituraRepository api;

  @override
  Future<Result<List<VersaoModel>>> versoes() =>
      listaComCache('versoes', api.versoes, VersaoModel.fromJson, (v) => v.toJson());

  @override
  Future<Result<List<TestamentoModel>>> testamentos() =>
      listaComCache('testamentos', api.testamentos, TestamentoModel.fromJson, (t) => t.toJson());

  @override
  Future<Result<List<LivroModel>>> livros() =>
      listaComCache('livros', api.livros, LivroModel.fromJson, (l) => l.toJson());

  @override
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId) =>
      listaComCache('indice:$versaId', () => api.indice(versaId), IndiceCapituloModel.fromJson, (i) => i.toJson());

  @override
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero) async {
    final salvos = await local(() => store.versiculosDoCapitulo(versaId, livrId, capiNumero));
    if (salvos != null && salvos.isNotEmpty) return Result.ok(salvos);

    final result = await remoto(() => api.capitulo(versaId, livrId, capiNumero));
    if (result case Ok<List<VersiculoTextoModel>>(value: final versiculos)) {
      await local(() => store.salvarVersiculos(versaId, versiculos));
    }
    return result;
  }

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async {
    final usuaId = usuarioLogado();
    if (usuaId == null) return api.lidos(versaId);

    final chave = LeituraLocalStore.chaveLidos(usuaId, versaId);
    final result = await listaComCache(chave, () => api.lidos(versaId), CapituloLidoModel.fromJson, (l) => l.toJson());
    final List<CapituloLidoModel> base;
    switch (result) {
      case Ok<List<CapituloLidoModel>>(value: final value):
        base = value;
      case Error<List<CapituloLidoModel>>(error: final error):
        if (!apiInacessivel(error)) return result;
        base = const [];
    }
    return Result.ok(await local(() => _comPendentes(usuaId, versaId, base)) ?? base);
  }

  /// Aplica ao progresso [base] (o da API) as marcações pendentes da versão: cada capítulo soma a diferença entre o
  /// que está no aparelho e o último estado conhecido na API.
  Future<List<CapituloLidoModel>> _comPendentes(int usuaId, int versaId, List<CapituloLidoModel> base) async {
    final pendentes = await store.reacoesPendentes(usuaId, versaId: versaId);
    if (pendentes.isEmpty) return base;

    final capitulos = <String, ({int livrId, int capiNumero, int diferenca, DateTime? alteradoEm})>{};
    for (final r in pendentes) {
      final chave = CapituloLidoModel.chaveDe(r.coordenada.livrId, r.coordenada.capiNumero);
      final atual = capitulos[chave];
      final diferenca = (r.lido ? 1 : 0) - (r.lidoServidor ? 1 : 0);
      final alteradoEm = [
        atual?.alteradoEm,
        r.alteradoEm,
      ].nonNulls.fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      capitulos[chave] = (
        livrId: r.coordenada.livrId,
        capiNumero: r.coordenada.capiNumero,
        diferenca: (atual?.diferenca ?? 0) + diferenca,
        alteradoEm: alteradoEm,
      );
    }

    final porChave = {for (final lido in base) lido.chave: lido};
    List<LivroModel>? livros;
    for (final MapEntry(key: chave, value: c) in capitulos.entries) {
      if (c.diferenca == 0) continue;
      final atual = porChave[chave];
      if (atual != null) {
        final versLidos = (atual.versLidos + c.diferenca).clamp(0, atual.versTotal);
        if (versLidos == 0) {
          porChave.remove(chave);
        } else {
          porChave[chave] = atual.copyWith(versLidos: versLidos, lidoEm: c.diferenca > 0 ? c.alteradoEm : null);
        }
        continue;
      }
      if (c.diferenca < 0) continue;
      final resumo = await store.resumoCapitulo(versaId, c.livrId, c.capiNumero);
      if (resumo == null) continue;
      livros ??= await lerLista('livros', LivroModel.fromJson) ?? const [];
      porChave[chave] = CapituloLidoModel(
        livrId: c.livrId,
        livrNome: resumo.livrNome,
        livrAbrev: livros.where((l) => l.livrId == c.livrId).firstOrNull?.livrAbrev ?? '',
        capiNumero: c.capiNumero,
        versTotal: resumo.versTotal,
        versLidos: c.diferenca.clamp(0, resumo.versTotal),
        lidoEm: c.alteradoEm,
      );
    }

    return porChave.values.toList()..sort((a, b) {
      final livro = a.livrId.compareTo(b.livrId);
      return livro != 0 ? livro : a.capiNumero.compareTo(b.capiNumero);
    });
  }

  @override
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido}) async {
    final usuaId = usuarioLogado();
    final versiculos = usuaId == null
        ? null
        : await local(() => store.versiculosDoCapitulo(versaId, livrId, capiNumero));
    if (usuaId == null || versiculos == null || versiculos.isEmpty) {
      return api.marcarCapitulo(versaId, livrId, capiNumero, lido: lido);
    }

    final gravou = await local(
      () => store
          .gravarReacoesCapitulo(
            usuaId,
            (versaId: versaId, livrId: livrId, capiNumero: capiNumero),
            [for (final v in versiculos) v.versId],
            lido: lido,
          )
          .then((_) => true),
    );
    if (gravou == null) return api.marcarCapitulo(versaId, livrId, capiNumero, lido: lido);

    sincronizacao.agendar();
    return Result.ok(versiculos.length);
  }

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoesCapitulo(int versaId, int livrId, int capiNumero) async {
    final usuaId = usuarioLogado();
    if (usuaId == null) return api.reacoesCapitulo(versaId, livrId, capiNumero);

    final inicio = agoraMs;
    final result = await remoto(() => api.reacoesCapitulo(versaId, livrId, capiNumero));
    switch (result) {
      case Ok<List<VersiculoReacaoModel>>(value: final reacoes):
        await local(
          () => store.mesclarReacoesServidor(
            usuaId,
            (versaId: versaId, livrId: livrId, capiNumero: capiNumero),
            reacoes,
            inicio: inicio,
          ),
        );
      case Error<List<VersiculoReacaoModel>>(error: final error):
        if (!apiInacessivel(error)) return result;
    }

    final locais = await local(() => store.reacoesDoCapitulo(usuaId, versaId, livrId, capiNumero));
    if (locais == null) return result;
    return Result.ok([for (final r in locais) r.toModel(usuaId)]);
  }
}
