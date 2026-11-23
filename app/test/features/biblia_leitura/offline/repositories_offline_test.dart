import 'dart:convert';

import 'package:app/data/local/leitura_local_store.dart';
import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/data/model/biblia/versiculo_indicacao_model.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/biblia/biblia_leitura/offline/biblia_leitura_repository_offline.dart';
import 'package:app/features/biblia/biblia_leitura/offline/falha_api.dart';
import 'package:app/features/biblia/biblia_leitura/offline/versiculo_indicacao_repository_offline.dart';
import 'package:app/features/biblia/biblia_leitura/offline/versiculo_reacao_repository_offline.dart';
import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

import 'offline_fakes.dart';

void main() {
  late Ambiente amb;
  late BibliaLeituraRepositoryOffline biblia;
  late VersiculoReacaoRepositoryOffline reacao;
  late VersiculoIndicacaoRepositoryOffline indicacao;

  setUp(() {
    amb = Ambiente();
    biblia = BibliaLeituraRepositoryOffline(
      api: amb.bibliaApi,
      store: amb.store,
      conectividade: amb.conectividade,
      sincronizacao: amb.sincronizacao,
      usuarioLogado: () => usuaId,
    );
    reacao = VersiculoReacaoRepositoryOffline(
      api: amb.reacaoApi,
      store: amb.store,
      conectividade: amb.conectividade,
      sincronizacao: amb.sincronizacao,
      usuarioLogado: () => usuaId,
    );
    indicacao = VersiculoIndicacaoRepositoryOffline(
      api: amb.indicacaoApi,
      store: amb.store,
      conectividade: amb.conectividade,
      sincronizacao: amb.sincronizacao,
      usuarioLogado: () => usuaId,
    );
  });
  tearDown(() => amb.fechar());

  T valor<T>(Result<T> result) => (result as Ok<T>).value;

  group('BibliaLeituraRepositoryOffline', () {
    test('capítulo: busca na API uma vez e depois lê do aparelho, mesmo sem conexão', () async {
      expect(valor(await biblia.capitulo(versaId, 43, 3)), hasLength(3));
      amb.conectividade.online = false;
      expect(valor(await biblia.capitulo(versaId, 43, 3)), hasLength(3));
      expect(amb.bibliaApi.chamadas, ['capitulo']);
    });

    test('capítulo nunca aberto, sem conexão: erro semConexao sem chamar a API', () async {
      amb.conectividade.online = false;
      final result = await biblia.capitulo(versaId, 43, 3);
      expect((result as Error).error, isA<HttpServiceException>().having((e) => e.message, 'message', kSemConexao));
      expect(amb.bibliaApi.chamadas, isEmpty);
    });

    test('versões: sem resposta da API usa a última guardada', () async {
      await biblia.versoes();
      amb.bibliaApi.versoesResult = Result.error(erroRede());
      final versoes = valor(await biblia.versoes());
      expect(versoes.single.versaCodigo, 'ARC');
    });

    test('versões: sem resposta e sem cache devolve o erro da API', () async {
      amb.bibliaApi.versoesResult = Result.error(erroRede());
      expect(await biblia.versoes(), isA<Error<List<VersaoModel>>>());
    });

    test('marcar capítulo grava no aparelho, conta como lido no progresso e espera a conexão', () async {
      await amb.store.salvarVersiculos(versaId, joao3());
      amb.conectividade.online = false;

      expect(valor(await biblia.marcarCapitulo(versaId, 43, 3, lido: true)), 3);

      expect(amb.bibliaApi.chamadas, isEmpty);
      final lidos = valor(await biblia.lidos(versaId));
      expect(lidos.single.completo, isTrue);
      expect(lidos.single.livrNome, 'João');
      final reacoes = valor(await biblia.reacoesCapitulo(versaId, 43, 3));
      expect(reacoes.every((r) => r.vreaLido), isTrue);
      expect(await amb.store.contarPendentes(usuaId), 3);
    });

    test('progresso: a API (ou o guardado) com as marcações pendentes somadas', () async {
      await amb.store.salvarVersiculos(versaId, joao3());
      amb.bibliaApi.lidosResult = const Result.ok([
        CapituloLidoModel(livrId: 43, livrNome: 'João', livrAbrev: 'Jo', capiNumero: 3, versTotal: 3, versLidos: 1),
      ]);
      await biblia.lidos(versaId); // guarda o da API
      await amb.store.mesclarReacoesServidor(usuaId, joao3Coord, const [
        VersiculoReacaoModel(vreaId: 1, versId: 100, usuaId: usuaId, vreaLido: true),
      ], inicio: 0);

      amb.conectividade.online = false;
      await amb.store.gravarReacao(usuaId, 101, joao3Coord, lido: true);
      expect(valor(await biblia.lidos(versaId)).single.versLidos, 2);

      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: false);
      await amb.store.gravarReacao(usuaId, 101, joao3Coord, lido: false);
      expect(valor(await biblia.lidos(versaId)), isEmpty);
    });

    test('reações do capítulo: resposta da API não desfaz a marcação pendente', () async {
      await amb.store.salvarVersiculos(versaId, joao3());
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      amb.conectividade.online = true;
      amb.bibliaApi.reacoesCapituloResult = const Result.ok([
        VersiculoReacaoModel(vreaId: 3, versId: 100, usuaId: usuaId, vreaLido: false),
      ]);
      // A sincronização agendada falharia; aqui só interessa a leitura.
      amb.bibliaApi.marcarCapituloResult = Result.error(erroRede());

      final reacoes = valor(await biblia.reacoesCapitulo(versaId, 43, 3));
      expect(reacoes.single.vreaLido, isTrue);
      expect(reacoes.single.vreaId, 3);
    });
  });

  group('VersiculoReacaoRepositoryOffline', () {
    test('versículo com texto no aparelho: marca offline e devolve a reação do aparelho', () async {
      await amb.store.salvarVersiculos(versaId, joao3());
      amb.conectividade.online = false;

      final gravada = valor(await reacao.incluir(const VersiculoReacaoModel(versId: 101, vreaLido: true)));
      expect((gravada.versId, gravada.vreaLido, gravada.usuaId), (101, true, usuaId));

      final lista = valor(await reacao.reacoes(101));
      expect(lista.single.vreaLido, isTrue);
      expect(amb.reacaoApi.chamadas, isEmpty);
    });

    test('versículo sem texto no aparelho (ex.: versículo do dia) vai direto à API', () async {
      await reacao.incluir(const VersiculoReacaoModel(versId: 555, vreaLido: true));
      expect(amb.reacaoApi.chamadas, ['incluir:555:true']);
    });
  });

  group('VersiculoIndicacaoRepositoryOffline', () {
    setUp(() => amb.store.salvarVersiculos(versaId, joao3()));

    test('indicar offline devolve o id provisório -versId; remover pelo provisório esconde a indicação', () async {
      amb.conectividade.online = false;

      final gravada = valor(await indicacao.incluir(const VersiculoIndicacaoModel(versId: 100, vindComentario: 'ok')));
      expect(gravada.vindId, -100);
      expect(valor(await indicacao.indicacoesCapitulo(versaId, 43, 3)).single.vindComentario, 'ok');

      expect(await indicacao.excluir(-100), isA<Ok<void>>());
      expect(valor(await indicacao.indicacoesCapitulo(versaId, 43, 3)), isEmpty);
      expect(amb.indicacaoApi.chamadas, isEmpty);
    });

    test('indicações do versículo offline: as guardadas de outros usuários mais a do aparelho', () async {
      amb.indicacaoApi.indicacoesResult = const Result.ok([
        VersiculoIndicacaoModel(vindId: 1, versId: 100, usuaId: 99),
        VersiculoIndicacaoModel(vindId: 2, versId: 100, usuaId: usuaId, vindComentario: 'api'),
      ]);
      await indicacao.indicacoes(100);
      expect(jsonDecode((await amb.store.lerCache(LeituraLocalStore.chaveIndicacoes(usuaId, 100)))!), hasLength(2));

      amb.conectividade.online = false;
      await indicacao.alterar(const VersiculoIndicacaoModel(vindId: 2, versId: 100, vindComentario: 'offline'));
      final lista = valor(await indicacao.indicacoes(100));
      expect(lista, hasLength(2));
      expect(lista.firstWhere((i) => i.usuaId == usuaId).vindComentario, 'offline');
    });

    test('erro de dados da API (não de rede) é devolvido', () async {
      amb.indicacaoApi.indicacoesCapituloResult = Result.error(HandledException(message: 'formatoIndicacaoInvalido'));
      expect(await indicacao.indicacoesCapitulo(versaId, 43, 3), isA<Error<List<VersiculoIndicacaoModel>>>());
    });
  });
}
