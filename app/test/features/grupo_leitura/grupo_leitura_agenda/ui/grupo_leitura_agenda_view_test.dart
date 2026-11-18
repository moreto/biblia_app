import 'package:app/data/model/leitura/leitura_agenda_model.dart';
import 'package:app/features/grupo_leitura/grupo_leitura/use_case/grupo_leitura_usecase.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/ui/grupo_leitura_agenda_view.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/ui/grupo_leitura_agenda_viewmodel.dart';
import 'package:app/features/grupo_leitura/grupo_leitura_agenda/use_case/grupo_leitura_agenda_usecase.dart';
import 'package:commons/commons.dart';
import 'package:service/service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../grupo_leitura_fakes.dart';

void main() {
  late FakeGrupoLeituraAgendaRepository repository;

  setUp(() => repository = FakeGrupoLeituraAgendaRepository());

  GrupoLeituraAgendaUseCase criarUseCase() => GrupoLeituraAgendaUseCase(
    grupoLeituraAgendaRepository: repository,
    grupoLeituraUseCase: criarGrupoLeituraUseCase(),
  );

  group('LeituraAgendaModel', () {
    test('toJson envia data e hora sem fuso e as horas como texto', () {
      expect(leituraDia1.toJson(), {
        'lageId': 20,
        'leitId': 1,
        'lageTitulo': 'Gênesis 1-3',
        'lageTexto': 'Criação',
        'lageDataHora': '2026-11-20T19:30:00',
        'lageHoraAtividade': null,
        'lageRepete': 3,
        'lageFimRepete': 1,
        'lageLembrete': 2,
      });
    });

    test('fromJson aceita snake_case', () {
      final item = LeituraAgendaModel.fromJson({
        'lage_id': 1,
        'leit_id': 2,
        'lage_titulo': 'T',
        'lage_data_hora': '2026-11-20T19:30:00',
        'lage_repete': '2',
        'lage_lembrete': 4,
      });
      expect(item.lageDataHora, DateTime(2026, 11, 20, 19, 30));
      expect(item.lageRepete, 2);
      expect(item.lageLembrete, 4);
      expect(item.lageFimRepete, isNull);
    });
  });

  group('GrupoLeituraAgendaUseCase', () {
    test('agenda por data, os sem data por último', () async {
      final result = await criarUseCase().agenda(1);
      expect((result as Ok<List<LeituraAgendaModel>>).value.map((i) => i.lageId), [20, 21]);
    });

    test('validar exige título e limita título e texto', () {
      final useCase = criarUseCase();
      expect(useCase.validar(const LeituraAgendaModel(leitId: 1, lageTitulo: ' ')), 'informeTituloAgenda');
      expect(useCase.validar(LeituraAgendaModel(leitId: 1, lageTitulo: 't' * 129)), 'tituloAgendaMuitoLongo');
      expect(
        useCase.validar(LeituraAgendaModel(leitId: 1, lageTitulo: 't', lageTexto: 'x' * 4001)),
        'textoAgendaMuitoLongo',
      );
      expect(useCase.validar(const LeituraAgendaModel(leitId: 1, lageTitulo: 't')), isNull);
    });

    test('opcoes: pelo código ou pelo nome, só ativos, na ordem; em cache', () async {
      final useCase = criarUseCase();
      final opcoes = await useCase.opcoes();
      expect(opcoes.repeticoes, [(chave: 2, rotulo: 'diaInteiro'), (chave: 3, rotulo: 'segunda')]);
      expect(opcoes.fimRepeticoes.map((o) => o.rotulo), ['nunca', 'naData']);
      expect(opcoes.lembretes.map((o) => o.chave), [1, 2], reason: 'configuração sem código, achada pelo nome');

      await useCase.opcoes();
      expect(repository.configuracoesConsultadas, 1);
      expect(GrupoLeituraAgendaUseCase.rotulo(2, opcoes.lembretes), '15minutos');
      expect(GrupoLeituraAgendaUseCase.rotulo(9, opcoes.lembretes), isNull);
    });

    test('opcoes: falha nas configurações devolve vazio sem cache', () async {
      repository.erroConfiguracoes = HttpServiceException(message: 'erroGeralApi');
      final useCase = criarUseCase();
      expect((await useCase.opcoes()).lembretes, isEmpty);
      repository.erroConfiguracoes = null;
      expect((await useCase.opcoes()).lembretes, hasLength(2));
    });

    test('validar: repetição e lembrete exigem data; opção fora da configuração é recusada', () async {
      final useCase = criarUseCase();
      await useCase.opcoes();
      const semData = LeituraAgendaModel(leitId: 1, lageTitulo: 't', lageRepete: 2);
      expect(useCase.validar(semData), 'repeticaoExigeData');
      expect(
        useCase.validar(const LeituraAgendaModel(leitId: 1, lageTitulo: 't', lageLembrete: 1)),
        'lembreteExigeData',
      );
      final data = DateTime(2026, 1, 1);
      expect(
        useCase.validar(LeituraAgendaModel(leitId: 1, lageTitulo: 't', lageDataHora: data, lageLembrete: 9)),
        GrupoLeituraAgendaUseCase.kOpcaoInvalida,
      );
      expect(useCase.validar(leituraDia1), isNull);
    });

    test('salvar descarta o fim da repetição sem repetição', () async {
      final useCase = criarUseCase();
      await useCase.opcoes();
      await useCase.salvar(
        grupoMeu,
        LeituraAgendaModel(leitId: 1, lageTitulo: 't', lageDataHora: DateTime(2026, 1, 1), lageFimRepete: 2),
      );
      expect(repository.incluidos.single.lageFimRepete, isNull);
    });

    test('salvar: só o dono; grava sem espaços e mantém os campos não editados', () async {
      final useCase = criarUseCase();
      final negado = await useCase.salvar(grupoOutro, const LeituraAgendaModel(leitId: 2, lageTitulo: 'x'));
      expect(((negado as Error).error as HandledException).message, GrupoLeituraUseCase.kSomenteDonoAltera);

      await useCase.salvar(
        grupoMeu,
        const LeituraAgendaModel(leitId: 1, lageTitulo: ' Novo ', lageTexto: ' ', lageHoraAtividade: '07:00:00'),
      );
      final gravado = repository.incluidos.single;
      expect(gravado.lageTitulo, 'Novo');
      expect(gravado.lageTexto, isNull);
      expect(gravado.lageHoraAtividade, '07:00:00');

      await useCase.opcoes();
      await useCase.salvar(grupoMeu, leituraDia1);
      expect(repository.alterados.single.lageId, 20);
    });

    test('horas: leitura, formato da API e junção com a data', () {
      expect(GrupoLeituraAgendaUseCase.hora('7:05:00'), '07:05');
      expect(GrupoLeituraAgendaUseCase.hora('25:00'), isNull);
      expect(GrupoLeituraAgendaUseCase.horaApi(7, 5), '07:05:00');
      expect(
        GrupoLeituraAgendaUseCase.juntar(DateTime(2026, 1, 2), (hora: 8, minuto: 30)),
        DateTime(2026, 1, 2, 8, 30),
      );
      expect(GrupoLeituraAgendaUseCase.juntar(null, (hora: 8, minuto: 30)), isNull);
      expect(GrupoLeituraAgendaUseCase.dataHora(DateTime(2026, 11, 20, 19, 30)), '20/11/2026 19:30');
    });
  });

  group('GrupoLeituraAgendaView', () {
    Future<void> pump(WidgetTester tester, {int leitId = 1, void Function(LeituraAgendaModel)? onAtividades}) async {
      final viewModel = GrupoLeituraAgendaViewmodel(grupoLeituraAgendaUseCase: criarUseCase())
        ..selecionar(leitId)
        ..abrir();
      await pumpTela(
        tester,
        GrupoLeituraAgendaView(
          viewModel: viewModel,
          onEditar: (_) {},
          onExcluir: (_) {},
          onAtividades: onAtividades ?? (_) {},
        ),
      );
    }

    testWidgets('lista título, data e hora, texto, repetição e lembrete; sem data mostra "semData"', (tester) async {
      await pump(tester);
      expect(find.text('Gênesis 1-3'), findsOneWidget);
      expect(find.text('20/11/2026 19:30'), findsOneWidget);
      expect(find.text('Criação'), findsOneWidget);
      expect(find.text('segunda · nunca'), findsOneWidget);
      expect(find.text('lembrete: 15minutos'), findsOneWidget);
      expect(find.text('Revisão'), findsOneWidget);
      expect(find.text('semData'), findsOneWidget);
    });

    testWidgets('tocar no item abre as atividades; menu do dono tem editar e excluir', (tester) async {
      LeituraAgendaModel? aberto;
      await pump(tester, onAtividades: (item) => aberto = item);

      await tester.tap(find.text('Gênesis 1-3'));
      expect(aberto?.lageId, 20);

      await tester.tap(find.byTooltip('acoes').first);
      await tester.pumpAndSettle();
      expect(find.text('atividades'), findsOneWidget);
      expect(find.text('editar'), findsOneWidget);
      expect(find.text('excluir'), findsOneWidget);
    });

    testWidgets('grupo de outro usuário: menu só com atividades; sem itens mostra a mensagem', (tester) async {
      await pump(tester, leitId: 2);
      expect(find.text('nenhumItemAgenda'), findsOneWidget);

      repository = FakeGrupoLeituraAgendaRepository({
        2: [leituraSemData],
      });
      await pump(tester, leitId: 2);
      await tester.tap(find.byTooltip('acoes').first);
      await tester.pumpAndSettle();
      expect(find.text('atividades'), findsOneWidget);
      expect(find.text('editar'), findsNothing);
    });
  });
}
