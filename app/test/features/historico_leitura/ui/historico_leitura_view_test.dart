import 'package:app/config/versao_preferencia.dart';
import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/historico_leitura/repository/historico_leitura_repository.dart';
import 'package:app/features/historico_leitura/repository/historico_leitura_repository_impl.dart';
import 'package:app/features/historico_leitura/ui/historico_leitura_view.dart';
import 'package:app/features/historico_leitura/ui/historico_leitura_viewmodel.dart';
import 'package:app/features/historico_leitura/use_case/historico_leitura_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

const _arc = VersaoModel(versaId: 1, versaCodigo: 'ARC', versaNome: 'Almeida Revista e Corrigida');
const _nvi = VersaoModel(versaId: 2, versaCodigo: 'NVI', versaNome: 'Nova Versão Internacional');

/// "Agora" fixo dos testes: 20/11/2026 às 10h (horário local).
final _agora = DateTime(2026, 11, 20, 10);

CapituloLidoModel _lido(
  int livrId,
  int capiNumero, {
  String livrNome = 'João',
  int versTotal = 10,
  int versLidos = 10,
  DateTime? lidoEm,
}) => CapituloLidoModel(
  livrId: livrId,
  livrNome: livrNome,
  livrAbrev: '',
  capiNumero: capiNumero,
  versTotal: versTotal,
  versLidos: versLidos,
  lidoEm: lidoEm,
);

/// Histórico por versão; registra as versões consultadas. [erros] substitui a resposta de uma versão.
class _FakeHistoricoLeituraRepository implements HistoricoLeituraRepository {
  _FakeHistoricoLeituraRepository(this.porVersao);

  final Map<int, List<CapituloLidoModel>> porVersao;
  final erros = <int, Exception>{};
  final chamadas = <int>[];

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async {
    chamadas.add(versaId);
    final erro = erros[versaId];
    return erro != null ? Result.error(erro) : Result.ok(porVersao[versaId] ?? const []);
  }
}

/// Só versões e lidos são usados por esta tela; os demais métodos da leitura não são chamados.
class _FakeBibliaLeituraRepository implements BibliaLeituraRepository {
  List<CapituloLidoModel> lidosResposta = const [];

  @override
  Future<Result<List<VersaoModel>>> versoes() async => const Result.ok([_arc, _nvi]);

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async => Result.ok(lidosResposta);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVersaoPreferencia implements VersaoPreferencia {
  @override
  int? versaoId;

  @override
  void setVersaoId(int versaId) => versaoId = versaId;
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale: locale, translations: const []));

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

void main() {
  late _FakeHistoricoLeituraRepository repository;
  late _FakeVersaoPreferencia preferencia;

  setUp(() {
    repository = _FakeHistoricoLeituraRepository({
      _arc.versaId: [
        _lido(1, 1, livrNome: 'Gênesis', lidoEm: DateTime(2026, 11, 18, 9)),
        _lido(43, 3, versLidos: 4, lidoEm: DateTime(2026, 11, 20, 8)),
        _lido(43, 1, lidoEm: DateTime(2026, 11, 19, 21)),
        _lido(19, 23, livrNome: 'Salmos', versTotal: 6, versLidos: 2),
      ],
      _nvi.versaId: [_lido(40, 5, livrNome: 'Mateus', versLidos: 3, lidoEm: DateTime(2026, 11, 20, 7))],
    });
    preferencia = _FakeVersaoPreferencia();
  });

  HistoricoLeituraUseCase criarUseCase() => HistoricoLeituraUseCase(
    historicoLeituraRepository: repository,
    bibliaLeituraUseCase: BibliaLeituraUseCase(
      bibliaLeituraRepository: _FakeBibliaLeituraRepository(),
      versaoPreferencia: preferencia,
    ),
    relogio: () => _agora,
  );

  HistoricoLeituraViewmodel criar() => HistoricoLeituraViewmodel(historicoLeituraUseCase: criarUseCase());

  group('HistoricoLeituraRepositoryImpl', () {
    test('usa o repository da leitura (offline) para os lidos', () async {
      final leitura = _FakeBibliaLeituraRepository()..lidosResposta = [_lido(43, 3)];
      final result = await HistoricoLeituraRepositoryImpl(leitura: leitura).lidos(1);
      expect((result as Ok<List<CapituloLidoModel>>).value.single.chave, '43:3');
    });
  });

  group('HistoricoLeituraUseCase', () {
    test('ordena do mais recente para o mais antigo, sem data no fim', () async {
      final result = await criarUseCase().historico(_arc.versaId);
      expect((result as Ok<List<CapituloLidoModel>>).value.map((c) => c.chave), ['43:3', '43:1', '1:1', '19:23']);
    });

    test('ignora capítulos sem versículo lido', () async {
      repository.porVersao[_arc.versaId] = [_lido(43, 3, versLidos: 0), _lido(43, 4)];
      final result = await criarUseCase().historico(_arc.versaId);
      expect((result as Ok<List<CapituloLidoModel>>).value.map((c) => c.chave), ['43:4']);
    });

    test('404 registroNaoEncontrado vira histórico vazio e outros erros são repassados', () async {
      repository.erros[1] = HttpServiceException(message: 'registroNaoEncontrado', code: 404);
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      repository.erros[2] = erro;

      expect((await criarUseCase().historico(1) as Ok<List<CapituloLidoModel>>).value, isEmpty);
      expect((await criarUseCase().historico(2) as Error).error, same(erro));
    });

    test('filtra concluídos e em andamento e conta cada filtro', () {
      final useCase = criarUseCase();
      final lista = [_lido(43, 3, versLidos: 4), _lido(43, 1), _lido(1, 1)];

      expect(useCase.filtrar(lista, HistoricoFiltro.todos), hasLength(3));
      expect(useCase.filtrar(lista, HistoricoFiltro.concluidos).map((c) => c.chave), ['43:1', '1:1']);
      expect(useCase.filtrar(lista, HistoricoFiltro.emAndamento).map((c) => c.chave), ['43:3']);
      expect(useCase.quantidade(lista, HistoricoFiltro.concluidos), 2);
    });

    test('resumo soma concluídos, em andamento e versículos lidos (sem passar do total)', () {
      final resumo = criarUseCase().resumo([_lido(43, 3, versLidos: 4), _lido(43, 1), _lido(1, 1, versLidos: 12)]);
      expect(resumo, (capitulos: 3, concluidos: 2, emAndamento: 1, versiculos: 24));
    });

    test('fração de versículos lidos fica entre 0 e 1', () {
      final useCase = criarUseCase();
      expect(useCase.fracao(_lido(1, 1, versLidos: 5)), 0.5);
      expect(useCase.fracao(_lido(1, 1, versLidos: 15)), 1);
      expect(useCase.fracao(_lido(1, 1, versTotal: 0, versLidos: 0)), 0);
    });

    test('agrupa por dia: hoje, ontem, outros dias e sem data por último', () async {
      final useCase = criarUseCase();
      final historico = (await useCase.historico(_arc.versaId) as Ok<List<CapituloLidoModel>>).value;
      final grupos = useCase.agrupar(historico);

      expect(grupos.map((g) => g.periodo), [
        PeriodoHistorico.hoje,
        PeriodoHistorico.ontem,
        PeriodoHistorico.dia,
        PeriodoHistorico.semData,
      ]);
      expect(grupos.map((g) => g.chave), ['hoje', 'ontem', null, 'semData']);
      expect(grupos[2].dia, DateTime(2026, 11, 18));
      expect(grupos.last.capitulos.single.chave, '19:23');
    });

    test('continuar é o capítulo em andamento mais recente', () {
      final useCase = criarUseCase();
      expect(useCase.continuar([_lido(43, 1), _lido(43, 3, versLidos: 4), _lido(1, 1, versLidos: 1)])?.chave, '43:3');
      expect(useCase.continuar([_lido(43, 1)]), isNull);
    });

    test('o destino abre o capítulo na versão do histórico', () {
      expect(criarUseCase().destino(2, _lido(43, 3)).toQuery(), {'versaId': '2', 'livrId': '43', 'capiNumero': '3'});
    });
  });

  group('HistoricoLeituraViewmodel', () {
    test('carrega o histórico na versão salva pelo usuário', () async {
      preferencia.versaoId = _nvi.versaId;
      final viewModel = criar();
      await pumpEventQueue();

      expect(viewModel.versao?.versaId, _nvi.versaId);
      expect(repository.chamadas, [_nvi.versaId]);
      expect(viewModel.historico?.single.livrNome, 'Mateus');
    });

    test('filtro muda a lista sem nova consulta', () async {
      final viewModel = criar();
      await pumpEventQueue();
      viewModel.selecionarFiltro(HistoricoFiltro.emAndamento);

      expect(viewModel.capitulos.map((c) => c.chave), ['43:3', '19:23']);
      expect(repository.chamadas, [_arc.versaId]);
    });

    test('atualizar recarrega só o histórico da versão atual', () async {
      final viewModel = criar();
      await pumpEventQueue();
      await viewModel.carregarCommand.execute();

      expect(repository.chamadas, [_arc.versaId, _arc.versaId]);
    });

    test('trocar a versão recarrega e salva a preferência; falha mantém a anterior', () async {
      final viewModel = criar();
      await pumpEventQueue();
      await viewModel.versaoCommand.execute(_nvi);

      expect(viewModel.versao?.versaId, _nvi.versaId);
      expect(preferencia.versaoId, _nvi.versaId);

      repository.erros[_arc.versaId] = HttpServiceException(message: 'erroGeralApi', code: 500);
      await viewModel.versaoCommand.execute(_arc);

      expect(viewModel.versaoCommand.error, isTrue);
      expect(viewModel.versao?.versaId, _nvi.versaId);
      expect(viewModel.historico?.single.livrNome, 'Mateus');
    });
  });

  group('HistoricoLeituraView', () {
    /// Monta a tela num GoRouter com a rota da leitura, que mostra a URI recebida.
    Future<void> montar(WidgetTester tester, HistoricoLeituraViewmodel viewModel) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/teste',
        routes: [
          GoRoute(
            path: '/teste',
            builder: (_, _) => HistoricoLeituraView(viewModel: viewModel),
          ),
          GoRoute(
            path: Routes.bibliaLeitura,
            builder: (_, state) => Scaffold(body: Text('leitura ${state.uri.query}')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mostra resumo, continuar leitura, filtros e grupos por dia', (tester) async {
      await montar(tester, criar());

      expect(find.text('historicoLeitura'), findsOneWidget);
      expect(find.text('continuarLeitura'), findsOneWidget);
      expect(find.text('todos (4)'), findsOneWidget);
      expect(find.text('filtroConcluidos (2)'), findsOneWidget);
      expect(find.text('filtroEmAndamento (2)'), findsOneWidget);
      expect(find.text('hoje'), findsOneWidget);
      expect(find.text('ontem'), findsOneWidget);
      expect(find.text('semData'), findsOneWidget);
      expect(find.text('Gênesis 1'), findsOneWidget);
      // "João 3" aparece no "Continuar leitura" e na lista.
      expect(find.text('João 3'), findsNWidgets(2));
    });

    testWidgets('filtro de concluídos esconde os capítulos em andamento', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('filtroConcluidos (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Salmos 23'), findsNothing);
      expect(find.text('João 1'), findsOneWidget);
    });

    testWidgets('sem leitura mostra a mensagem de histórico vazio', (tester) async {
      repository.porVersao[_arc.versaId] = const [];
      await montar(tester, criar());

      expect(find.text('nenhumaLeituraRegistrada'), findsOneWidget);
      expect(find.text('continuarLeitura'), findsNothing);
    });

    testWidgets('erro no primeiro carregamento mostra tentar novamente', (tester) async {
      repository.erros[_arc.versaId] = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());

      expect(find.text('erroGeralApi'), findsOneWidget);
      expect(find.text('tentarNovamente'), findsOneWidget);
    });

    testWidgets('tocar num capítulo abre a leitura nele, na versão do histórico', (tester) async {
      await montar(tester, criar());
      await tester.tap(find.text('Gênesis 1'));
      await tester.pumpAndSettle();

      expect(find.text('leitura versaId=1&livrId=1&capiNumero=1'), findsOneWidget);
    });
  });
}
