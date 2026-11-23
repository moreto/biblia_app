import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/versiculo_indicacao_model.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/biblia/biblia_leitura/offline/leitura_sincronizacao.dart';
import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'offline_fakes.dart';

void main() {
  late Ambiente amb;

  setUp(() async {
    amb = Ambiente();
    await amb.store.salvarVersiculos(versaId, joao3());
  });
  tearDown(() => amb.fechar());

  group('reações', () {
    test('capítulo inteiro com a mesma marcação vai num só PUT e atualiza o progresso guardado', () async {
      await amb.store.gravarReacoesCapitulo(usuaId, joao3Coord, [100, 101, 102], lido: true);
      amb.bibliaApi.lidosResult = const Result.ok([
        CapituloLidoModel(livrId: 43, livrNome: 'João', livrAbrev: 'Jo', capiNumero: 3, versTotal: 3, versLidos: 3),
      ]);

      await amb.sincronizacao.sincronizar();

      expect(amb.bibliaApi.chamadas, ['marcarCapitulo:true', 'lidos']);
      expect(amb.reacaoApi.chamadas, isEmpty);
      expect(amb.sincronizacao.pendentes, 0);
      expect(await amb.store.lerCache('u$usuaId:lidos:$versaId'), contains('"versLidos":3'));
    });

    test('versículo a versículo: altera a reação que já existe (mantendo o comentário) e inclui a que falta', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      await amb.store.gravarReacao(usuaId, 101, joao3Coord, lido: true);
      await amb.store.gravarReacao(usuaId, 102, joao3Coord, lido: false);
      amb.bibliaApi.reacoesCapituloResult = const Result.ok([
        VersiculoReacaoModel(vreaId: 40, versId: 100, usuaId: usuaId, vreaLido: false, vreaComentario: 'meu'),
      ]);

      await amb.sincronizacao.sincronizar();

      // 102 desmarcado e sem reação na API: nada a gravar.
      expect(amb.reacaoApi.chamadas, ['alterar:100:true', 'incluir:101:true']);
      expect(amb.reacaoApi.gravadas.first.vreaComentario, 'meu');
      expect(amb.reacaoApi.gravadas.first.vreaId, 40);
      expect(amb.sincronizacao.pendentes, 0);
      expect((await amb.store.reacao(usuaId, 101))!.vreaId, isNotNull);
    });

    test('sem resposta da API para e mantém as pendências', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      amb.bibliaApi.reacoesCapituloResult = Result.error(erroRede());

      await amb.sincronizacao.sincronizar();

      expect(amb.sincronizacao.pendentes, 1);
      expect(amb.sincronizacao.consumirDescartada(), isFalse);
    });

    test('sessão vencida também mantém as pendências', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      amb.reacaoApi.erroGravar = erroHttp(400, 'tokenInvalido');

      await amb.sincronizacao.sincronizar();

      expect(amb.sincronizacao.pendentes, 1);
    });

    test('dado recusado pela API (4xx) descarta e volta ao estado da API', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      amb.reacaoApi.erroGravar = erroHttp(400);

      await amb.sincronizacao.sincronizar();

      expect(amb.sincronizacao.pendentes, 0);
      expect((await amb.store.reacao(usuaId, 100))!.lido, isFalse);
      expect(amb.sincronizacao.consumirDescartada(), isTrue);
    });

    test('erro 5xx tenta de novo até o limite e então descarta', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      amb.reacaoApi.erroGravar = erroHttp(500, 'ERRO_GERAL_API');

      for (var i = 1; i < LeituraSincronizacao.maxTentativas; i++) {
        await amb.sincronizacao.sincronizar();
        expect(amb.sincronizacao.pendentes, 1, reason: 'tentativa $i');
      }
      await amb.sincronizacao.sincronizar();
      expect(amb.sincronizacao.pendentes, 0);
    });

    test('sem conexão não chama a API', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      amb.conectividade.online = false;

      await amb.sincronizacao.sincronizar();

      expect(amb.bibliaApi.chamadas, isEmpty);
      expect(amb.sincronizacao.pendentes, 1);
    });

    test('a conexão voltar dispara a sincronização', () async {
      await amb.store.gravarReacoesCapitulo(usuaId, joao3Coord, [100, 101, 102], lido: true);
      amb.conectividade.online = false;
      await amb.sincronizacao.iniciar();
      await amb.sincronizacao.sincronizar();
      expect(amb.sincronizacao.pendentes, 3);

      amb.conectividade.mudar(true);
      await pumpEventQueue();
      await amb.sincronizacao.sincronizar();

      expect(amb.bibliaApi.chamadas, contains('marcarCapitulo:true'));
      expect(amb.sincronizacao.pendentes, 0);
    });

    test('alteração feita durante o envio continua pendente', () async {
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
      final enviando = amb.sincronizacao.sincronizar();
      await amb.store.gravarReacao(usuaId, 100, joao3Coord, lido: false);
      await enviando;

      // Pedido durante a sincronização: roda de novo e envia o estado final.
      await amb.sincronizacao.sincronizar();
      expect((await amb.store.reacao(usuaId, 100))!.pendente, isFalse);
      expect((await amb.store.reacao(usuaId, 100))!.lidoServidor, isFalse);
    });
  });

  group('indicações', () {
    test('sem vindId consulta a API antes: altera a que já existe em vez de duplicar', () async {
      await amb.store.gravarIndicacao(usuaId, 100, joao3Coord, comentario: 'novo');
      amb.indicacaoApi.indicacoesResult = const Result.ok([
        VersiculoIndicacaoModel(vindId: 1, versId: 100, usuaId: 99),
        VersiculoIndicacaoModel(vindId: 33, versId: 100, usuaId: usuaId, vindComentario: 'antigo'),
      ]);

      await amb.sincronizacao.sincronizar();

      expect(amb.indicacaoApi.chamadas, ['indicacoes:100', 'alterar:33:novo']);
      expect((await amb.store.indicacao(usuaId, 100))!.pendente, isFalse);
    });

    test('inclui quando a API não tem e guarda o vindId devolvido', () async {
      await amb.store.gravarIndicacao(usuaId, 100, joao3Coord);

      await amb.sincronizacao.sincronizar();

      expect(amb.indicacaoApi.chamadas, ['indicacoes:100', 'incluir:100:null']);
      expect((await amb.store.indicacao(usuaId, 100))!.vindId, 900);
    });

    test('remoção apaga na API (404 conta como removida) e some do aparelho', () async {
      await amb.store.mesclarIndicacoesServidor(usuaId, joao3Coord, const [
        VersiculoIndicacaoModel(vindId: 33, versId: 100, usuaId: usuaId),
      ], inicio: 0);
      await amb.store.gravarIndicacao(usuaId, 100, joao3Coord, excluida: true);
      amb.indicacaoApi.excluirResult = Result.error(erroHttp(404, 'registroNaoEncontrado'));

      await amb.sincronizacao.sincronizar();

      expect(amb.indicacaoApi.chamadas, ['excluir:33']);
      expect(await amb.store.indicacao(usuaId, 100), isNull);
      expect(amb.sincronizacao.pendentes, 0);
    });
  });
}
