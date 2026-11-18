import 'package:app/data/model/leitura/leitura_agenda_atividade_model.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/use_case/grupo_leitura_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/use_case/grupo_leitura_agenda_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_atividade/ui/grupo_leitura_atividade_view.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_atividade/ui/grupo_leitura_atividade_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_atividade/use_case/grupo_leitura_atividade_usecase.dart';
import 'package:commons/commons.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../grupo_leitura_fakes.dart';

void main() {
  late FakeGrupoLeituraAtividadeRepository repository;
  late FakeGrupoLeituraAgendaRepository agendaRepository;

  setUp(() {
    repository = FakeGrupoLeituraAtividadeRepository();
    agendaRepository = FakeGrupoLeituraAgendaRepository();
  });

  GrupoLeituraAtividadeUseCase criarUseCase() => GrupoLeituraAtividadeUseCase(
    grupoLeituraAtividadeRepository: repository,
    grupoLeituraAgendaUseCase: GrupoLeituraAgendaUseCase(
      grupoLeituraAgendaRepository: agendaRepository,
      grupoLeituraUseCase: criarGrupoLeituraUseCase(),
    ),
  );

  test('LeituraAgendaAtividadeModel.fromJson aplica os padrões e rejeita concluída inválida', () {
    final model = LeituraAgendaAtividadeModel.fromJson({'laat_id': 1, 'lage_id': 2});
    expect(model.laatSeq, 0);
    expect(model.laatConcluida, isFalse);
    expect(() => LeituraAgendaAtividadeModel.fromJson({'lageId': 2, 'laatConcluida': 'sim'}), throwsFormatException);
  });

  group('GrupoLeituraAtividadeUseCase', () {
    test('atividades por sequência; livros em cache', () async {
      final useCase = criarUseCase();
      final result = await useCase.atividades(20);
      expect((result as Ok<List<LeituraAgendaAtividadeModel>>).value.map((a) => a.laatId), [30, 31]);

      await useCase.livros();
      await useCase.livros();
      expect(repository.livrosConsultados, 1);
    });

    test('validar exige texto ou livro', () {
      final useCase = criarUseCase();
      expect(useCase.validar(const LeituraAgendaAtividadeModel(lageId: 20, laatTexto: ' ')), 'informeTextoOuLivro');
      expect(useCase.validar(const LeituraAgendaAtividadeModel(lageId: 20, livrId: 1)), isNull);
      expect(useCase.validar(const LeituraAgendaAtividadeModel(lageId: 20, laatTexto: 'Ler')), isNull);
    });

    test('nova atividade vai para o fim; só o dono grava', () async {
      final useCase = criarUseCase();
      const nova = LeituraAgendaAtividadeModel(lageId: 0, laatTexto: ' Cantar ');

      final negado = await useCase.salvar(grupoOutro, leituraDia1, nova, const [lerCapitulo, orar]);
      expect(((negado as Error).error as HandledException).message, GrupoLeituraUseCase.kSomenteDonoAltera);

      await useCase.salvar(grupoMeu, leituraDia1, nova, const [lerCapitulo, orar]);
      final gravada = repository.incluidos.single;
      expect(gravada.laatSeq, 3);
      expect(gravada.lageId, 20);
      expect(gravada.laatTexto, 'Cantar');
    });

    test('alternarConcluida inverte a marca; nomeLivro e concluidas', () async {
      await criarUseCase().alternarConcluida(grupoMeu, lerCapitulo);
      expect(repository.alterados.single.laatConcluida, isTrue);

      expect(GrupoLeituraAtividadeUseCase.nomeLivro(lerCapitulo, const [genesis]), 'Gênesis');
      expect(GrupoLeituraAtividadeUseCase.nomeLivro(orar, const [genesis]), isNull);
      expect(GrupoLeituraAtividadeUseCase.concluidas(const [lerCapitulo, orar]), 1);
      expect(GrupoLeituraAtividadeUseCase.proximaSequencia(const []), 1);
    });
  });

  test('viewmodel abre no item pedido e troca de item', () async {
    agendaRepository = FakeGrupoLeituraAgendaRepository({
      1: [leituraDia1, leituraSemData],
    });
    final viewModel = GrupoLeituraAtividadeViewmodel(grupoLeituraAtividadeUseCase: criarUseCase())
      ..selecionar(1, lageId: 20)
      ..abrir();
    await pumpEventQueue();
    expect(viewModel.grupo, grupoMeu);
    expect(viewModel.item?.lageId, 20);
    expect(viewModel.atividades, hasLength(2));

    await viewModel.selecionarItemCommand.execute(21);
    expect(viewModel.item?.lageId, 21);
    expect(viewModel.atividades, isEmpty);
  });

  group('GrupoLeituraAtividadeView', () {
    Future<GrupoLeituraAtividadeViewmodel> pump(WidgetTester tester, {int leitId = 1}) async {
      final viewModel = GrupoLeituraAtividadeViewmodel(grupoLeituraAtividadeUseCase: criarUseCase())
        ..selecionar(leitId, lageId: 20)
        ..abrir();
      await pumpTela(tester, GrupoLeituraAtividadeView(viewModel: viewModel, onEditar: (_) {}, onExcluir: (_) {}));
      return viewModel;
    }

    testWidgets('mostra item, progresso, texto, livro e oração; o dono marca como concluída', (tester) async {
      await pump(tester);
      expect(find.text('Gênesis 1-3'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Ler'), findsOneWidget);
      expect(find.text('Gênesis'), findsOneWidget);
      expect(find.text('oracao'), findsOneWidget);

      await tester.tap(find.byTooltip('marcarConcluida'));
      await tester.pumpAndSettle();
      expect(repository.alterados.single.laatId, 30);
      expect(find.text('2/2'), findsOneWidget);
    });

    testWidgets('grupo de outro usuário não mostra ações nem a marca clicável', (tester) async {
      agendaRepository = FakeGrupoLeituraAgendaRepository({
        2: [leituraDia1],
      });
      await pump(tester, leitId: 2);
      expect(find.text('Ler'), findsOneWidget);
      expect(find.byTooltip('marcarConcluida'), findsNothing);
      expect(find.byTooltip('acoes'), findsNothing);
    });

    testWidgets('grupo sem agenda mostra a mensagem da agenda', (tester) async {
      agendaRepository = FakeGrupoLeituraAgendaRepository({1: []});
      await pump(tester);
      expect(find.text('nenhumItemAgenda'), findsOneWidget);
    });
  });
}
