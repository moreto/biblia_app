import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guarda as reações em memória, como a tabela `biblia.versiculo_reacao`.
class _FakeVersiculoReacaoRepository implements VersiculoReacaoRepository {
  _FakeVersiculoReacaoRepository([List<VersiculoReacaoModel>? iniciais]) : registros = [...?iniciais];

  final List<VersiculoReacaoModel> registros;
  int consultas = 0;
  final List<String> gravacoes = [];
  Exception? erroConsulta;

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId) async {
    consultas++;
    if (erroConsulta case final erro?) return Result.error(erro);
    return Result.ok(registros.where((r) => r.versId == versId).toList());
  }

  @override
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao) async {
    gravacoes.add('POST');
    final gravada = VersiculoReacaoModel(
      vreaId: registros.length + 100,
      versId: reacao.versId,
      usuaId: 7,
      vreaComentario: reacao.vreaComentario,
      vreaLido: reacao.vreaLido,
    );
    registros.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao) async {
    gravacoes.add('PUT');
    registros.removeWhere((r) => r.vreaId == reacao.vreaId);
    registros.add(reacao);
    return Result.ok(reacao);
  }
}

void main() {
  const usuario = 7;

  VersiculoReacaoUseCase criar(_FakeVersiculoReacaoRepository repository, {int? usuaId = usuario}) =>
      VersiculoReacaoUseCase(versiculoReacaoRepository: repository, usuarioLogado: () => usuaId);

  group('VersiculoReacaoUseCase.minhaReacao', () {
    test('considera só a reação do usuário logado', () async {
      final useCase = criar(
        _FakeVersiculoReacaoRepository(const [
          VersiculoReacaoModel(vreaId: 1, versId: 10, usuaId: 99, vreaLido: true),
          VersiculoReacaoModel(vreaId: 2, versId: 10, usuaId: usuario, vreaLido: false),
        ]),
      );
      final reacao = (await useCase.minhaReacao(10) as Ok<VersiculoReacaoModel?>).value;
      expect(reacao?.vreaId, 2);
    });

    test('sem reação do usuário devolve nulo', () async {
      final useCase = criar(
        _FakeVersiculoReacaoRepository(const [VersiculoReacaoModel(vreaId: 1, versId: 10, usuaId: 99, vreaLido: true)]),
      );
      expect((await useCase.minhaReacao(10) as Ok<VersiculoReacaoModel?>).value, isNull);
    });

    test('com registros duplicados vale o mais recente', () async {
      final useCase = criar(
        _FakeVersiculoReacaoRepository(const [
          VersiculoReacaoModel(vreaId: 5, versId: 10, usuaId: usuario, vreaLido: true),
          VersiculoReacaoModel(vreaId: 3, versId: 10, usuaId: usuario, vreaLido: false),
        ]),
      );
      expect((await useCase.minhaReacao(10) as Ok<VersiculoReacaoModel?>).value?.vreaId, 5);
    });

    test('sem usuário logado devolve headerInvalido', () async {
      final useCase = criar(_FakeVersiculoReacaoRepository(), usuaId: null);
      final erro = (await useCase.minhaReacao(10) as Error).error;
      expect((erro as HandledException).message, 'headerInvalido');
    });
  });

  group('VersiculoReacaoUseCase.alternarLido', () {
    test('sem reação inclui (POST) marcada como lida', () async {
      final repository = _FakeVersiculoReacaoRepository();
      final reacao = (await criar(repository).alternarLido(10, null) as Ok<VersiculoReacaoModel>).value;
      expect(repository.gravacoes, ['POST']);
      expect(reacao.vreaLido, isTrue);
    });

    test('com reação lida altera (PUT) para não lida e preserva o comentário', () async {
      const atual = VersiculoReacaoModel(
        vreaId: 1,
        versId: 10,
        usuaId: usuario,
        vreaComentario: 'Amém',
        vreaLido: true,
      );
      final repository = _FakeVersiculoReacaoRepository(const [atual]);
      final reacao = (await criar(repository).alternarLido(10, atual) as Ok<VersiculoReacaoModel>).value;
      expect(repository.gravacoes, ['PUT']);
      expect(repository.consultas, 0);
      expect(reacao.vreaLido, isFalse);
      expect(reacao.vreaComentario, 'Amém');
    });

    test('sem reação exibida consulta antes e altera a existente em vez de duplicar', () async {
      final repository = _FakeVersiculoReacaoRepository(const [
        VersiculoReacaoModel(vreaId: 1, versId: 10, usuaId: usuario, vreaLido: false),
      ]);
      final reacao = (await criar(repository).alternarLido(10, null) as Ok<VersiculoReacaoModel>).value;
      expect(repository.consultas, 1);
      expect(repository.gravacoes, ['PUT']);
      expect(reacao.vreaId, 1);
      expect(reacao.vreaLido, isTrue);
    });

    test('ao marcar como lido grava o comentário aparado', () async {
      final repository = _FakeVersiculoReacaoRepository();
      final reacao =
          (await criar(repository).alternarLido(10, null, comentario: '  Amém  ') as Ok<VersiculoReacaoModel>).value;
      expect(reacao.vreaLido, isTrue);
      expect(reacao.vreaComentario, 'Amém');
    });

    test('ao marcar como lido com comentário vazio remove o anterior', () async {
      const atual = VersiculoReacaoModel(
        vreaId: 1,
        versId: 10,
        usuaId: usuario,
        vreaComentario: 'Antigo',
        vreaLido: false,
      );
      final repository = _FakeVersiculoReacaoRepository(const [atual]);
      final reacao =
          (await criar(repository).alternarLido(10, atual, comentario: '   ') as Ok<VersiculoReacaoModel>).value;
      expect(reacao.vreaLido, isTrue);
      expect(reacao.vreaComentario, isNull);
    });

    test('ao desmarcar ignora o comentário informado e preserva o gravado', () async {
      const atual = VersiculoReacaoModel(
        vreaId: 1,
        versId: 10,
        usuaId: usuario,
        vreaComentario: 'Amém',
        vreaLido: true,
      );
      final repository = _FakeVersiculoReacaoRepository(const [atual]);
      final reacao =
          (await criar(repository).alternarLido(10, atual, comentario: 'outro') as Ok<VersiculoReacaoModel>).value;
      expect(reacao.vreaLido, isFalse);
      expect(reacao.vreaComentario, 'Amém');
    });

    test('comentário acima do limite devolve comentarioMaximo500 sem gravar', () async {
      final repository = _FakeVersiculoReacaoRepository();
      final result = await criar(repository)
          .alternarLido(10, null, comentario: 'a' * (VersiculoReacaoUseCase.comentarioMaximo + 1));
      expect(((result as Error).error as HandledException).message, 'comentarioMaximo500');
      expect(repository.gravacoes, isEmpty);
      expect(repository.consultas, 0);
    });

    test('erro na consulta prévia não grava nada', () async {
      final repository = _FakeVersiculoReacaoRepository()..erroConsulta = HandledException(message: 'erroApi');
      final result = await criar(repository).alternarLido(10, null);
      expect(result, isA<Error>());
      expect(repository.gravacoes, isEmpty);
    });
  });

  group('VersiculoReacaoModel', () {
    test('lê o JSON da API em camelCase', () {
      final model = VersiculoReacaoModel.fromJson({
        'vreaId': 1,
        'versId': 10,
        'usuaId': usuario,
        'vreaComentario': null,
        'vreaLido': true,
        'createdAt': '2026-11-07T10:00:00.000Z',
        'updatedAt': null,
      });
      expect(model.vreaId, 1);
      expect(model.versId, 10);
      expect(model.usuaId, usuario);
      expect(model.vreaLido, isTrue);
    });

    test('corpo do POST não leva usuaId', () {
      final json = const VersiculoReacaoModel(versId: 10, usuaId: usuario, vreaLido: true).toJson();
      expect(json.containsKey('usuaId'), isFalse);
      expect(json['versId'], 10);
      expect(json['vreaLido'], isTrue);
    });

    test('JSON sem vreaLido lança TypeError (vira formatoReacaoInvalido no repository)', () {
      expect(() => VersiculoReacaoModel.fromJson({'vreaId': 1, 'versId': 10}), throwsA(isA<TypeError>()));
    });
  });
}
