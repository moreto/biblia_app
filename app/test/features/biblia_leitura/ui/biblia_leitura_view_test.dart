import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/indice_capitulo_model.dart';
import 'package:app/data/model/biblia/livro_model.dart';
import 'package:app/data/model/biblia/testamento_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/data/model/biblia/versiculo_indicacao_model.dart';
import 'package:app/data/model/biblia/versiculo_texto_model.dart';
import 'package:app/features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_view.dart';
import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/capitulo_chip.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/biblia/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import 'package:app/features/biblia/versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _usuario = 7;

const _arc = VersaoModel(versaId: 1, versaCodigo: 'ARC', versaNome: 'Almeida Revista e Corrigida');
const _nvi = VersaoModel(versaId: 2, versaCodigo: 'NVI', versaNome: 'Nova Versão Internacional');

const _genesis = LivroModel(livrId: 1, testId: 1, livrNome: 'Gênesis', livrAbrev: 'Gn', livrCapituloCount: 2);
const _joao = LivroModel(livrId: 43, testId: 2, livrNome: 'João', livrAbrev: 'Jo', livrCapituloCount: 1);

IndiceCapituloModel _cap(LivroModel livro, int numero, int total) => IndiceCapituloModel(
  testId: livro.testId,
  livrId: livro.livrId,
  livrNome: livro.livrNome,
  capiNumero: numero,
  versTotal: total,
);

/// Bíblia em memória: Gênesis 1 (3 versículos), Gênesis 2 (2), Gênesis 3 sem versículos na versão e João 1 (2).
/// Os capítulos lidos ficam em [lidosPorVersao]; [marcarCapitulo] grava neles como a API.
class _FakeBibliaLeituraRepository implements BibliaLeituraRepository {
  _FakeBibliaLeituraRepository({Map<int, List<CapituloLidoModel>>? lidos}) : lidosPorVersao = lidos ?? {};

  final Map<int, List<CapituloLidoModel>> lidosPorVersao;
  final marcacoes = <({int versaId, int livrId, int capiNumero, bool lido})>[];
  Exception? erroVersoes;
  Exception? erroMarcar;

  final _indice = [_cap(_genesis, 1, 3), _cap(_genesis, 2, 2), _cap(_genesis, 3, 0), _cap(_joao, 1, 2)];

  @override
  Future<Result<List<VersaoModel>>> versoes() async =>
      erroVersoes == null ? const Result.ok([_arc, _nvi]) : Result.error(erroVersoes!);

  @override
  Future<Result<List<TestamentoModel>>> testamentos() async => const Result.ok([
    TestamentoModel(testId: 1, testNome: 'Antigo Testamento'),
    TestamentoModel(testId: 2, testNome: 'Novo Testamento'),
  ]);

  @override
  Future<Result<List<LivroModel>>> livros() async => const Result.ok([_genesis, _joao]);

  @override
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId) async =>
      Result.ok(versaId == _nvi.versaId ? _indice.where((c) => c.livrId == _joao.livrId).toList() : _indice);

  @override
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero) async {
    final total = _indice.firstWhere((c) => c.livrId == livrId && c.capiNumero == capiNumero).versTotal;
    final livro = livrId == _genesis.livrId ? _genesis : _joao;
    return Result.ok([
      for (var n = 1; n <= total; n++)
        VersiculoTextoModel(
          versId: livrId * 1000 + capiNumero * 100 + n,
          versNumero: n,
          versTexto: '${livro.livrNome} $capiNumero texto $n',
          livrId: livrId,
          livrNome: livro.livrNome,
          capiNumero: capiNumero,
        ),
    ]);
  }

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async => Result.ok(lidosPorVersao[versaId] ?? const []);

  @override
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido}) async {
    if (erroMarcar case final erro?) return Result.error(erro);
    marcacoes.add((versaId: versaId, livrId: livrId, capiNumero: capiNumero, lido: lido));
    return Result.ok(_indice.firstWhere((c) => c.livrId == livrId && c.capiNumero == capiNumero).versTotal);
  }
}

/// Indicações em memória; as do [_usuario] são as do usuário logado.
class _FakeVersiculoIndicacaoRepository implements VersiculoIndicacaoRepository {
  _FakeVersiculoIndicacaoRepository([List<VersiculoIndicacaoModel>? iniciais]) : registros = [...?iniciais];

  final List<VersiculoIndicacaoModel> registros;
  final excluidos = <int>[];

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoes(int versId) async =>
      Result.ok(registros.where((r) => r.versId == versId).toList());

  @override
  Future<Result<VersiculoIndicacaoModel>> incluir(VersiculoIndicacaoModel indicacao) async {
    final gravada = VersiculoIndicacaoModel(
      vindId: 100 + registros.length,
      versId: indicacao.versId,
      usuaId: _usuario,
      vindComentario: indicacao.vindComentario,
    );
    registros.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<VersiculoIndicacaoModel>> alterar(VersiculoIndicacaoModel indicacao) async {
    registros
      ..removeWhere((r) => r.vindId == indicacao.vindId)
      ..add(indicacao);
    return Result.ok(indicacao);
  }

  @override
  Future<Result<void>> excluir(int vindId) async {
    excluidos.add(vindId);
    registros.removeWhere((r) => r.vindId == vindId);
    return const Result.ok(null);
  }
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

CapituloLidoModel _lido(LivroModel livro, int capitulo, int lidos, int total, [DateTime? em]) => CapituloLidoModel(
  livrId: livro.livrId,
  livrNome: livro.livrNome,
  livrAbrev: livro.livrAbrev,
  capiNumero: capitulo,
  versTotal: total,
  versLidos: lidos,
  lidoEm: em,
);

void main() {
  late _FakeBibliaLeituraRepository repository;
  late _FakeVersiculoIndicacaoRepository indicacoes;

  setUp(() {
    repository = _FakeBibliaLeituraRepository(
      lidos: {
        _arc.versaId: [
          _lido(_genesis, 1, 3, 3, DateTime(2026, 11, 1)),
          _lido(_genesis, 2, 1, 2, DateTime(2026, 11, 5)),
        ],
      },
    );
    indicacoes = _FakeVersiculoIndicacaoRepository();
  });

  BibliaLeituraUseCase leituraUseCase() => BibliaLeituraUseCase(bibliaLeituraRepository: repository);

  VersiculoIndicacaoUseCase indicacaoUseCase() =>
      VersiculoIndicacaoUseCase(versiculoIndicacaoRepository: indicacoes, usuarioLogado: () => _usuario);

  Future<BibliaLeituraViewmodel> criarViewModel() async {
    final viewModel = BibliaLeituraViewmodel(
      bibliaLeituraUseCase: leituraUseCase(),
      versiculoIndicacaoUseCase: indicacaoUseCase(),
    );
    await pumpEventQueue();
    return viewModel;
  }

  group('BibliaLeituraUseCase', () {
    test('agrupa o índice por livro e descarta capítulos sem versículos na versão', () async {
      final indice = (await leituraUseCase().indice(_arc.versaId) as Ok<Map<int, List<IndiceCapituloModel>>>).value;
      expect(indice.keys, [_genesis.livrId, _joao.livrId]);
      expect(indice[_genesis.livrId]!.map((c) => c.capiNumero), [1, 2]);
    });

    test('histórico vai do mais recente para o mais antigo, sem data no fim', () {
      final historico = leituraUseCase().historico([
        _lido(_joao, 1, 1, 2),
        _lido(_genesis, 1, 3, 3, DateTime(2026, 11, 1)),
        _lido(_genesis, 2, 1, 2, DateTime(2026, 11, 5)),
      ]);
      expect(historico.map((c) => c.chave), ['1:2', '1:1', '43:1']);
    });

    test('vizinho passa de um livro para o outro e é nulo nas pontas', () async {
      final useCase = leituraUseCase();
      final indice = (await useCase.indice(_arc.versaId) as Ok<Map<int, List<IndiceCapituloModel>>>).value;
      const livros = [_genesis, _joao];
      expect(useCase.vizinho(indice, livros, (livrId: 1, capiNumero: 2), 1), (livrId: 43, capiNumero: 1));
      expect(useCase.vizinho(indice, livros, (livrId: 43, capiNumero: 1), -1), (livrId: 1, capiNumero: 2));
      expect(useCase.vizinho(indice, livros, (livrId: 1, capiNumero: 1), -1), isNull);
      expect(useCase.vizinho(indice, livros, (livrId: 43, capiNumero: 1), 1), isNull);
    });

    test('marca o capítulo não completo e desmarca o completo', () async {
      final useCase = leituraUseCase();
      final marcado = await useCase.alternarCapitulo(1, _cap(_genesis, 2, 2), _genesis, _lido(_genesis, 2, 1, 2));
      expect((marcado as Ok<CapituloLidoModel?>).value?.completo, isTrue);

      final desmarcado = await useCase.alternarCapitulo(1, _cap(_genesis, 1, 3), _genesis, _lido(_genesis, 1, 3, 3));
      expect((desmarcado as Ok<CapituloLidoModel?>).value, isNull);
      expect(repository.marcacoes.map((m) => m.lido), [true, false]);
    });
  });

  group('VersiculoIndicacaoUseCase', () {
    test('conta todas as indicações e separa a mais recente do usuário logado', () async {
      indicacoes.registros.addAll(const [
        VersiculoIndicacaoModel(vindId: 1, versId: 5, usuaId: 3),
        VersiculoIndicacaoModel(vindId: 2, versId: 5, usuaId: _usuario, vindComentario: 'antiga'),
        VersiculoIndicacaoModel(vindId: 4, versId: 5, usuaId: _usuario, vindComentario: 'nova'),
        VersiculoIndicacaoModel(vindId: 6, versId: 9, usuaId: _usuario),
      ]);
      final result = (await indicacaoUseCase().indicacoes(5) as Ok<IndicacoesVersiculo>).value;
      expect(result.total, 3);
      expect(result.minha?.vindComentario, 'nova');
    });

    test('inclui quando o usuário ainda não indicou e altera quando já indicou', () async {
      final useCase = indicacaoUseCase();
      final incluida = (await useCase.indicar(5, null, comentario: '  bom  ') as Ok<VersiculoIndicacaoModel>).value;
      expect(incluida.vindComentario, 'bom');

      final alterada = (await useCase.indicar(5, incluida, comentario: '') as Ok<VersiculoIndicacaoModel>).value;
      expect(alterada.vindId, incluida.vindId);
      expect(alterada.vindComentario, isNull);
      expect(indicacoes.registros, hasLength(1));
    });

    test('comentário acima do limite devolve comentarioMaximo500', () async {
      final result = await indicacaoUseCase().indicar(5, null, comentario: 'x' * 501);
      expect(((result as Error).error as HandledException).message, 'comentarioMaximo500');
      expect(indicacoes.registros, isEmpty);
    });

    test('remove a indicação do usuário', () async {
      final result = await indicacaoUseCase().remover(
        const VersiculoIndicacaoModel(vindId: 8, versId: 5, usuaId: _usuario),
      );
      expect(result, isA<Ok<void>>());
      expect(indicacoes.excluidos, [8]);
    });
  });

  group('BibliaLeituraViewmodel', () {
    test('carrega versões, livros, índice e progresso da primeira versão', () async {
      final viewModel = await criarViewModel();
      expect(viewModel.carregarCommand.completed, isTrue);
      expect(viewModel.versao?.versaCodigo, 'ARC');
      expect(viewModel.livros.map((l) => l.livrNome), ['Gênesis', 'João']);
      expect(viewModel.capitulosLidosDo(_genesis.livrId), 1);
      expect(viewModel.lidoDe(_genesis.livrId, 2)?.completo, isFalse);
      expect(viewModel.historico.first.capiNumero, 2);
    });

    test('filtra os livros pelo testamento', () async {
      final viewModel = await criarViewModel();
      viewModel.selecionarTestamento(2);
      expect(viewModel.livros.map((l) => l.livrNome), ['João']);
      viewModel.selecionarTestamento(null);
      expect(viewModel.livros, hasLength(2));
    });

    test('abre o capítulo, marca como lido e navega para o próximo', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      expect(viewModel.versiculos, hasLength(2));
      expect(viewModel.proximo, (livrId: 43, capiNumero: 1));

      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.lidoAtual?.completo, isTrue);
      expect(viewModel.capitulosLidosDo(_genesis.livrId), 2);

      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.lidoAtual, isNull);
      expect(repository.marcacoes.map((m) => m.lido), [true, false]);
    });

    test('erro ao marcar mantém o progresso anterior', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      repository.erroMarcar = HandledException(message: 'erroApi');
      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.marcarLidoCommand.error, isTrue);
      expect(viewModel.lidoAtual?.versLidos, 1);
    });

    test('trocar a versão recarrega o índice e fecha o capítulo que a versão não tem', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 1));
      await viewModel.versaoCommand.execute(_nvi);
      expect(viewModel.versao?.versaCodigo, 'NVI');
      expect(viewModel.livros.map((l) => l.livrNome), ['João']);
      expect(viewModel.capitulo, isNull);
      expect(viewModel.historico, isEmpty);
    });

    test('indica e remove a indicação do versículo selecionado', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      await viewModel.indicacoesCommand.execute(viewModel.versiculos!.first);
      expect(viewModel.indicacoes?.total, 0);

      await viewModel.indicarCommand.execute('gostei');
      expect(viewModel.indicacoes?.total, 1);
      expect(viewModel.indicacoes?.minha?.vindComentario, 'gostei');

      await viewModel.removerIndicacaoCommand.execute();
      expect(viewModel.indicacoes?.total, 0);
      expect(viewModel.indicacoes?.minha, isNull);
    });

    test('falha no carregamento deixa o índice nulo', () async {
      repository.erroVersoes = HandledException(message: 'erroApi');
      final viewModel = await criarViewModel();
      expect(viewModel.carregarCommand.error, isTrue);
      expect(viewModel.indice, isNull);
    });
  });

  group('BibliaLeituraView', () {
    Future<BibliaLeituraViewmodel> montar(WidgetTester tester) async {
      final viewModel = BibliaLeituraViewmodel(
        bibliaLeituraUseCase: leituraUseCase(),
        versiculoIndicacaoUseCase: indicacaoUseCase(),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
          home: BibliaLeituraView(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('mostra os livros com o progresso e abre o capítulo tocado', (tester) async {
      await montar(tester);
      expect(find.text('leituraBiblica'), findsOneWidget);
      expect(find.text('Gênesis'), findsOneWidget);
      expect(find.text('1/2 capitulosLidos'), findsOneWidget);

      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      expect(find.byType(CapituloChip), findsNWidgets(2));

      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 2'), findsOneWidget);
      expect(find.textContaining('Gênesis 2 texto 1'), findsOneWidget);
      expect(find.text('1/2 versiculosLidos'), findsOneWidget);

      await tester.tap(find.text('marcarCapituloLido'));
      await tester.pumpAndSettle();
      expect(find.text('capituloLido'), findsOneWidget);
      expect(find.text('desmarcarCapituloLido'), findsOneWidget);
    });

    testWidgets('a versão é escolhida no índice, acima dos testamentos, e não na AppBar', (tester) async {
      final viewModel = await montar(tester);
      final selecao = find.byType(DropdownButtonFormField<int>);
      expect(selecao, findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: selecao), findsNothing);
      expect(tester.getTopLeft(selecao).dy, lessThan(tester.getTopLeft(find.byType(ChoiceChip).first).dy));

      await tester.tap(selecao);
      await tester.pumpAndSettle();
      await tester.tap(find.text('NVI · Nova Versão Internacional').last);
      await tester.pumpAndSettle();
      expect(viewModel.versao?.versaCodigo, 'NVI');
      expect(find.text('Gênesis'), findsNothing);
      expect(find.text('João'), findsOneWidget);
    });

    testWidgets('o histórico lista o que foi lido e abre o capítulo', (tester) async {
      await montar(tester);
      await tester.tap(find.byTooltip('historicoLeitura'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 2'), findsOneWidget);
      expect(find.text('Gênesis 1'), findsOneWidget);

      await tester.tap(find.text('Gênesis 1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gênesis 1 texto 3'), findsOneWidget);
      expect(find.text('capituloLido'), findsOneWidget);
    });

    testWidgets('tocar o versículo abre a indicação e permite indicar', (tester) async {
      await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('João 1 texto 1'));
      await tester.pumpAndSettle();
      expect(find.text('João 1:1'), findsOneWidget);
      expect(find.text('0 indicacoes'), findsOneWidget);

      await tester.tap(find.text('indicarVersiculo'));
      await tester.pumpAndSettle();
      expect(find.text('1 indicacoes · voceIndicou'), findsOneWidget);
      expect(find.text('removerIndicacao'), findsOneWidget);
    });
  });
}
