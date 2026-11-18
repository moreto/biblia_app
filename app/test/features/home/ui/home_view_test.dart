import 'package:app/config/ultimo_capitulo_preferencia.dart';
import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/indice_capitulo_model.dart';
import 'package:app/data/model/biblia/livro_model.dart';
import 'package:app/data/model/biblia/testamento_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/data/model/biblia/versiculo_texto_model.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/access/home/ui/home_view.dart';
import 'package:app/features/access/home/ui/home_viewmodel.dart';
import 'package:app/features/access/home/use_case/home_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Textos aparecem como as próprias chaves (`find.text('biblia')`).
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

const _arc = VersaoModel(versaId: 1, versaCodigo: 'ARC', versaNome: 'Almeida Revista e Corrigida');
const _genesis = LivroModel(livrId: 1, testId: 1, livrNome: 'Gênesis', livrAbrev: 'Gn', livrCapituloCount: 50);
const _exodo = LivroModel(livrId: 2, testId: 1, livrNome: 'Êxodo', livrAbrev: 'Êx', livrCapituloCount: 40);

IndiceCapituloModel _cap(LivroModel livro, int numero) => IndiceCapituloModel(
  testId: livro.testId,
  livrId: livro.livrId,
  livrNome: livro.livrNome,
  capiNumero: numero,
  versTotal: 10,
);

/// Só versões, livros e índice são usados pela home; Êxodo não tem capítulos na versão.
class _FakeBibliaLeituraRepository implements BibliaLeituraRepository {
  Exception? erroVersoes;
  int chamadasVersoes = 0;

  @override
  Future<Result<List<VersaoModel>>> versoes() async {
    chamadasVersoes++;
    return erroVersoes == null ? const Result.ok([_arc]) : Result.error(erroVersoes!);
  }

  @override
  Future<Result<List<LivroModel>>> livros() async => const Result.ok([_genesis, _exodo]);

  @override
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId) async =>
      Result.ok([_cap(_genesis, 1), _cap(_genesis, 2), _cap(_genesis, 3)]);

  @override
  Future<Result<List<TestamentoModel>>> testamentos() async => const Result.ok([]);

  @override
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero) async =>
      const Result.ok([]);

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async => const Result.ok([]);

  @override
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido}) async =>
      const Result.ok(0);

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoesCapitulo(int versaId, int livrId, int capiNumero) async =>
      const Result.ok([]);
}

class _FakeUltimoCapitulo implements UltimoCapituloPreferencia {
  @override
  UltimoCapitulo? ultimoCapitulo;

  @override
  void setUltimoCapitulo(UltimoCapitulo capitulo) => ultimoCapitulo = capitulo;
}

void main() {
  late _FakeBibliaLeituraRepository repository;
  late _FakeUltimoCapitulo ultimo;

  setUp(() {
    repository = _FakeBibliaLeituraRepository();
    ultimo = _FakeUltimoCapitulo();
  });

  HomeUseCase useCase([LerIdDispositivo? lerIdDispositivo]) => HomeUseCase(
    bibliaLeituraUseCase: BibliaLeituraUseCase(bibliaLeituraRepository: repository),
    ultimoCapituloPreferencia: ultimo,
    lerIdDispositivo: lerIdDispositivo ?? () async => 'abc123',
  );

  HomeViewmodel criar([LerIdDispositivo? lerIdDispositivo]) => HomeViewmodel(homeUseCase: useCase(lerIdDispositivo));

  /// A rota da leitura mostra a query recebida, para conferir o capítulo aberto.
  Future<void> montar(WidgetTester tester, [HomeViewmodel? viewModel]) async {
    final vm = viewModel ?? criar();
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => HomeView(viewModel: vm),
        ),
        GoRoute(
          path: Routes.bibliaLeitura,
          builder: (context, state) => Scaffold(body: Text('telaLeitura ${state.uri.query}')),
        ),
        GoRoute(
          path: Routes.homeOld,
          builder: (context, state) => const Scaffold(body: Text('telaHomeOld')),
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

  ButtonStyleButton botao(WidgetTester tester, String texto) => tester.widget<ButtonStyleButton>(
    find.ancestor(of: find.text(texto), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
  );

  group('HomeUseCase', () {
    test('devolve o id lido do aparelho', () async {
      final result = await useCase().idDispositivo();
      expect((result as Ok<String>).value, 'abc123');
    });

    test('plataforma sem id (web/desktop) vira dispositivoNaoIdentificado', () async {
      final result = await useCase(() async => throw UnsupportedError('web')).idDispositivo();
      expect(((result as Error<String>).error as HandledException).message, 'dispositivoNaoIdentificado');
    });

    test('id vazio vira dispositivoNaoIdentificado', () async {
      final result = await useCase(() async => '').idDispositivo();
      expect(((result as Error<String>).error as HandledException).message, 'dispositivoNaoIdentificado');
    });

    test('continuar usa o último capítulo aberto; sem ele, nulo', () {
      expect(useCase().continuarLeitura(), isNull);
      ultimo.setUltimoCapitulo((versaId: 1, livrId: 1, capiNumero: 3));
      final destino = useCase().continuarLeitura()!;
      expect(destino.toQuery(), {'versaId': '1', 'livrId': '1', 'capiNumero': '3'});
    });

    test('o seletor só lista livros com capítulos na versão', () async {
      final seletor = (await useCase().seletorCapitulo() as Ok<SeletorCapitulo>).value;
      expect(seletor.versao.versaCodigo, 'ARC');
      expect(seletor.livros.map((l) => l.livrNome), ['Gênesis']);
      expect(seletor.capitulos[_genesis.livrId], [1, 2, 3]);
    });
  });

  testWidgets('botões Bíblia, Continuar e Escolher capítulo, nesta ordem, acima do id', (tester) async {
    await montar(tester);

    final alturas = [
      for (final texto in ['biblia', 'continuarDeOndeParou', 'escolherCapitulo', 'abc123'])
        tester.getCenter(find.text(texto)).dy,
    ];
    expect(alturas, [...alturas]..sort());
    expect(find.text('home'), findsWidgets);
  });

  testWidgets('sem id mostra dispositivoNaoIdentificado', (tester) async {
    await montar(tester, criar(() async => throw UnsupportedError('web')));

    expect(find.text('dispositivoNaoIdentificado'), findsOneWidget);
  });

  testWidgets('Continuar fica desabilitado sem capítulo aberto', (tester) async {
    await montar(tester);

    expect(botao(tester, 'continuarDeOndeParou').onPressed, isNull);
  });

  testWidgets('Continuar abre a leitura no último capítulo', (tester) async {
    ultimo.setUltimoCapitulo((versaId: 1, livrId: 1, capiNumero: 3));
    await montar(tester);

    await tester.tap(find.text('continuarDeOndeParou'));
    await tester.pumpAndSettle();

    expect(find.text('telaLeitura versaId=1&livrId=1&capiNumero=3'), findsOneWidget);
  });

  testWidgets('Escolher capítulo: livro, depois capítulo, abre a leitura nele', (tester) async {
    await montar(tester);

    await tester.tap(find.text('escolherCapitulo'));
    await tester.pumpAndSettle();
    expect(find.text('Gênesis'), findsOneWidget);
    expect(find.text('Êxodo'), findsNothing);

    await tester.tap(find.text('Gênesis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(find.text('telaLeitura versaId=1&livrId=1&capiNumero=2'), findsOneWidget);
  });

  testWidgets('Escolher capítulo carrega livros e índice uma vez só', (tester) async {
    await montar(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('escolherCapitulo'));
      await tester.pumpAndSettle();
      // Fecha o sheet sem escolher (como o X ou arrastar).
      Navigator.of(tester.element(find.text('Gênesis'))).pop();
      await tester.pumpAndSettle();
    }
    expect(repository.chamadasVersoes, 1);
  });

  testWidgets('erro ao carregar o seletor mostra SnackBar', (tester) async {
    repository.erroVersoes = HandledException(message: 'erroApi');
    await montar(tester);

    await tester.tap(find.text('escolherCapitulo'));
    await tester.pumpAndSettle();

    expect(find.text('erroApi'), findsOneWidget);
  });

  testWidgets('o menu hambúrguer tem Home e Home antiga', (tester) async {
    await montar(tester);

    expect(find.byType(Drawer), findsNothing);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('menus'), findsOneWidget);
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('home')), findsOneWidget);

    await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('home')));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
    expect(find.text('biblia'), findsOneWidget);
  });

  testWidgets('a opção Home antiga do menu fecha o Drawer e abre /home-old', (tester) async {
    await montar(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('homeAntiga'));
    await tester.pumpAndSettle();

    expect(find.text('telaHomeOld'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('o botão Bíblia abre a leitura no índice', (tester) async {
    await montar(tester);

    await tester.tap(find.text('biblia'));
    await tester.pumpAndSettle();

    expect(find.text('telaLeitura '), findsOneWidget);
  });
}
