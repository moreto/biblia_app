import 'package:app/data/local/leitura_local_store.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'offline_fakes.dart';

void main() {
  late Ambiente amb;
  late LeituraLocalStore store;

  setUp(() {
    amb = Ambiente();
    store = amb.store;
  });
  tearDown(() => amb.fechar());

  test('salva versículos e lê o capítulo em ordem, com a coordenada de cada versículo', () async {
    await store.salvarVersiculos(versaId, joao3().reversed.toList());

    final capitulo = await store.versiculosDoCapitulo(versaId, 43, 3);
    expect(capitulo.map((v) => v.versNumero), [1, 2, 3]);
    expect(await store.coordenada(101), joao3Coord);
    expect(await store.coordenada(999), isNull);
    expect(await store.resumoCapitulo(versaId, 43, 3), (livrNome: 'João', versTotal: 3));
  });

  test('gravar marca como pendente e aumenta a versão; mesclar não sobrescreve a pendente', () async {
    await store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
    var r = (await store.reacao(usuaId, 100))!;
    expect((r.lido, r.pendente, r.versao, r.lidoServidor), (true, true, 1, false));

    await store.mesclarReacoesServidor(usuaId, joao3Coord, const [
      VersiculoReacaoModel(vreaId: 9, versId: 100, usuaId: usuaId, vreaLido: false, vreaComentario: 'api'),
      VersiculoReacaoModel(vreaId: 10, versId: 101, usuaId: usuaId, vreaLido: true),
    ], inicio: 0);

    r = (await store.reacao(usuaId, 100))!;
    expect((r.lido, r.pendente, r.vreaId, r.comentario), (true, true, 9, 'api'));
    final outra = (await store.reacao(usuaId, 101))!;
    expect((outra.lido, outra.pendente, outra.lidoServidor), (true, false, true));
    expect(await store.contarPendentes(usuaId), 1);
  });

  test('mesclar apaga linha sincronizada que a API não tem mais', () async {
    await store.mesclarReacoesServidor(usuaId, joao3Coord, const [
      VersiculoReacaoModel(vreaId: 10, versId: 101, usuaId: usuaId, vreaLido: true),
    ], inicio: 0);
    await store.mesclarReacoesServidor(usuaId, joao3Coord, const [], inicio: 0);
    expect(await store.reacao(usuaId, 101), isNull);
  });

  test('concluir só tira a pendência se a linha não mudou desde a leitura', () async {
    await store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
    await store.gravarReacao(usuaId, 100, joao3Coord, lido: false); // versão 2

    await store.concluirReacao(usuaId, 100, versao: 1, vreaId: 5, lidoEnviado: true);
    var r = (await store.reacao(usuaId, 100))!;
    expect((r.pendente, r.lidoServidor, r.vreaId), (true, true, 5));

    await store.concluirReacao(usuaId, 100, versao: 2, vreaId: 5, lidoEnviado: false);
    r = (await store.reacao(usuaId, 100))!;
    expect((r.pendente, r.lidoServidor), (false, false));
  });

  test('descartar volta ao estado da API', () async {
    await store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
    await store.descartarReacao(usuaId, 100, versao: 1);
    final r = (await store.reacao(usuaId, 100))!;
    expect((r.lido, r.pendente), (false, false));
  });

  test('limparUsuario mantém as pendências e apaga o resto do usuário', () async {
    await store.gravarReacao(usuaId, 100, joao3Coord, lido: true);
    await store.mesclarReacoesServidor(usuaId, joao3Coord, const [
      VersiculoReacaoModel(vreaId: 10, versId: 101, usuaId: usuaId, vreaLido: true),
    ], inicio: 0);
    await store.salvarCache(LeituraLocalStore.chaveLidos(usuaId, versaId), '[]');
    await store.salvarCache('versoes', '[]');

    await store.limparUsuario(usuaId);

    expect(await store.reacao(usuaId, 100), isNotNull);
    expect(await store.reacao(usuaId, 101), isNull);
    expect(await store.lerCache(LeituraLocalStore.chaveLidos(usuaId, versaId)), isNull);
    expect(await store.lerCache('versoes'), '[]');
  });
}
