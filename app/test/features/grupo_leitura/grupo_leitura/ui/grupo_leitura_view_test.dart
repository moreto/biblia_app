import 'package:app/data/model/leitura/leitura_model.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/repository/leitura_resposta.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/ui/grupo_leitura_view.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/ui/grupo_leitura_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/use_case/grupo_leitura_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/ui/grupo_leitura_agenda_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/use_case/grupo_leitura_agenda_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_atividade/ui/grupo_leitura_atividade_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_atividade/use_case/grupo_leitura_atividade_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_participante/ui/grupo_leitura_participante_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_participante/use_case/grupo_leitura_participante_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

import '../../grupo_leitura_fakes.dart';

void main() {
  group('LeituraModel', () {
    test('fromJson aceita camelCase e snake_case, com leitDono e datas', () {
      final camel = LeituraModel.fromJson({
        'leitId': 1,
        'leitNome': 'Plano',
        'usuaId': 7,
        'leitDescricao': 'Bíblia em um ano',
        'leitDono': true,
        'createdAt': '2026-11-13T10:00:00.000Z',
      });
      expect(camel.leitId, 1);
      expect(camel.leitDono, isTrue);
      expect(camel.createdAt, isNotNull);

      final snake = LeituraModel.fromJson({'leit_id': '2', 'leit_nome': 'Outro', 'leit_dono': false});
      expect(snake.leitId, 2);
      expect(snake.leitDono, isFalse);
      expect(LeituraModel.fromJson({'leitNome': 'Sem dono'}).leitDono, isFalse);
    });

    test('fromJson sem nome ou com leitDono inválido lança FormatException', () {
      expect(() => LeituraModel.fromJson({'leitId': 1}), throwsFormatException);
      expect(() => LeituraModel.fromJson({'leitNome': 'x', 'leitDono': 'sim'}), throwsFormatException);
    });

    test('toJson leva só id, nome e descrição', () {
      expect(grupoOutro.toJson(), {'leitId': 2, 'leitNome': 'Evangelhos', 'leitDescricao': 'Mateus a João'});
    });
  });

  group('LeituraResposta', () {
    test('lista converte, tipo inesperado vira respostaApiInvalida e item inválido vira formato', () async {
      final ok = await LeituraResposta.lista(
        Future.value(
          const Result.ok([
            {'leitNome': 'A'},
          ]),
        ),
        LeituraModel.fromJson,
      );
      expect((ok as Ok<List<LeituraModel>>).value.single.leitNome, 'A');

      final tipo = await LeituraResposta.lista(Future.value(const Result.ok({'x': 1})), LeituraModel.fromJson);
      expect(((tipo as Error).error as HandledException).message, 'respostaApiInvalida');

      final item = await LeituraResposta.lista(Future.value(const Result.ok([1])), LeituraModel.fromJson);
      expect(((item as Error).error as HandledException).message, LeituraResposta.kFormatoInvalido);
    });
  });

  group('GrupoLeituraUseCase', () {
    test('meusGrupos ordena por nome; 404 vira lista vazia; sem login, headerInvalido', () async {
      final result = await criarGrupoLeituraUseCase().meusGrupos();
      expect((result as Ok<List<LeituraModel>>).value.map((g) => g.leitNome), ['Evangelhos', 'Plano anual']);

      final repository = FakeGrupoLeituraRepository()..erro = HttpServiceException(message: 'registroNaoEncontrado');
      expect((await criarGrupoLeituraUseCase(repository).meusGrupos() as Ok).value, isEmpty);

      final semLogin = GrupoLeituraUseCase(
        grupoLeituraRepository: FakeGrupoLeituraRepository(),
        usuarioLogado: () => null,
      );
      expect(((await semLogin.meusGrupos() as Error).error as HandledException).message, 'headerInvalido');
    });

    test('validar exige nome e limita nome e descrição', () {
      final useCase = criarGrupoLeituraUseCase();
      expect(useCase.validar(const LeituraModel(leitNome: '  ')), 'informeNomeGrupo');
      expect(useCase.validar(LeituraModel(leitNome: 'x' * 257)), 'nomeGrupoMuitoLongo');
      expect(useCase.validar(LeituraModel(leitNome: 'ok', leitDescricao: 'd' * 513)), 'descricaoGrupoMuitoLonga');
      expect(useCase.validar(LeituraModel(leitNome: 'x' * 256, leitDescricao: 'd' * 512)), isNull);
    });

    test('salvar inclui sem id (sem espaços, descrição vazia nula) e devolve como dono', () async {
      final repository = FakeGrupoLeituraRepository();
      final result = await criarGrupoLeituraUseCase(repository)
          .salvar(const LeituraModel(leitNome: '  Novo  ', leitDescricao: ' '));
      expect(repository.incluidos.single.leitNome, 'Novo');
      expect(repository.incluidos.single.leitDescricao, isNull);
      expect((result as Ok<LeituraModel>).value.leitDono, isTrue);
    });

    test('só o dono altera e exclui', () async {
      final repository = FakeGrupoLeituraRepository();
      final useCase = criarGrupoLeituraUseCase(repository);

      final alterar = await useCase.salvar(grupoOutro);
      expect(((alterar as Error).error as HandledException).message, GrupoLeituraUseCase.kSomenteDonoAltera);
      final excluir = await useCase.excluir(grupoOutro);
      expect(((excluir as Error).error as HandledException).message, GrupoLeituraUseCase.kSomenteDonoAltera);
      expect(repository.alterados, isEmpty);
      expect(repository.excluidos, isEmpty);

      expect(await useCase.salvar(grupoMeu), isA<Ok>());
      expect(await useCase.excluir(grupoMeu), isA<Ok>());
      expect(repository.excluidos, [1]);
    });

    test('selecionado: o pedido, senão o primeiro; nulo sem grupos', () {
      expect(GrupoLeituraUseCase.selecionado(const [grupoMeu, grupoOutro], 2), grupoOutro);
      expect(GrupoLeituraUseCase.selecionado(const [grupoMeu, grupoOutro], 99), grupoMeu);
      expect(GrupoLeituraUseCase.selecionado(const [], 1), isNull);
    });
  });

  group('GrupoLeituraView', () {
    late FakeGrupoLeituraRepository repository;

    setUp(() => repository = FakeGrupoLeituraRepository());

    GrupoLeituraView criarView() {
      final grupoLeituraUseCase = criarGrupoLeituraUseCase(repository);
      final agendaUseCase = GrupoLeituraAgendaUseCase(
        grupoLeituraAgendaRepository: FakeGrupoLeituraAgendaRepository(),
        grupoLeituraUseCase: grupoLeituraUseCase,
      );
      return GrupoLeituraView(
        viewModel: GrupoLeituraViewmodel(grupoLeituraUseCase: grupoLeituraUseCase),
        participanteViewModel: GrupoLeituraParticipanteViewmodel(
          grupoLeituraParticipanteUseCase: GrupoLeituraParticipanteUseCase(
            grupoLeituraParticipanteRepository: FakeGrupoLeituraParticipanteRepository(),
            grupoLeituraUseCase: grupoLeituraUseCase,
          ),
        ),
        agendaViewModel: GrupoLeituraAgendaViewmodel(grupoLeituraAgendaUseCase: agendaUseCase),
        atividadeViewModel: GrupoLeituraAtividadeViewmodel(
          grupoLeituraAtividadeUseCase: GrupoLeituraAtividadeUseCase(
            grupoLeituraAtividadeRepository: FakeGrupoLeituraAtividadeRepository(),
            grupoLeituraAgendaUseCase: agendaUseCase,
          ),
        ),
      );
    }

    test('GrupoLeituraViewmodel carrega os grupos ao ser criado', () async {
      final viewModel = GrupoLeituraViewmodel(grupoLeituraUseCase: criarGrupoLeituraUseCase(repository));
      await pumpEventQueue();
      expect(viewModel.gruposCommand.completed, isTrue);
      expect(viewModel.grupos, hasLength(2));
    });

    testWidgets('mostra as abas, os grupos com o papel e o botão de novo grupo', (tester) async {
      await pumpTela(tester, criarView(), scaffold: false);

      expect(find.text('gruposLeitura'), findsOneWidget);
      for (final aba in GrupoLeituraAba.values) {
        expect(find.text(aba.rotulo), findsOneWidget);
      }
      expect(find.text('Plano anual'), findsOneWidget);
      expect(find.text('Evangelhos'), findsOneWidget);
      expect(find.text('Mateus a João'), findsOneWidget);
      expect(find.text('donoDoGrupo'), findsOneWidget);
      expect(find.text('participanteDoGrupo'), findsOneWidget);
      expect(find.text('novoGrupoLeitura'), findsOneWidget);
    });

    testWidgets('menu do grupo de outro usuário não tem editar nem excluir', (tester) async {
      await pumpTela(tester, criarView(), scaffold: false);

      await tester.tap(find.byTooltip('acoes').first); // Evangelhos (de outro) vem primeiro
      await tester.pumpAndSettle();
      expect(find.text('participantes'), findsNWidgets(2), reason: 'aba e item do menu');
      expect(find.text('editar'), findsNothing);
      expect(find.text('excluir'), findsNothing);
    });

    testWidgets('"Novo grupo" valida e grava', (tester) async {
      await pumpTela(tester, criarView(), scaffold: false);

      await tester.tap(find.text('novoGrupoLeitura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.text('informeNomeGrupo'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Salmos');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(repository.incluidos.single.leitNome, 'Salmos');
      expect(find.text('Salmos'), findsOneWidget);
      expect(find.text('registroSalvo'), findsOneWidget);
    });

    testWidgets('sem grupos mostra a mensagem; erro no primeiro carregamento oferece tentar novamente', (tester) async {
      repository = FakeGrupoLeituraRepository(const []);
      await pumpTela(tester, criarView(), scaffold: false);
      expect(find.text('nenhumGrupoLeitura'), findsOneWidget);

      repository = FakeGrupoLeituraRepository()..erro = HttpServiceException(message: 'erroGeralApi');
      await pumpTela(tester, criarView(), scaffold: false);
      expect(find.text('erroGeralApi'), findsOneWidget);
      expect(find.text('tentarNovamente'), findsOneWidget);
    });
  });
}
