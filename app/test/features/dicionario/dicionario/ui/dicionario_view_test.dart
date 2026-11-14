import 'package:app/data/model/dicionario/dicionario_busca_model.dart';
import 'package:app/data/model/dicionario/dicionario_verbete_model.dart';
import 'package:app/features/dicionario/dicionario/repository/dicionario_repository.dart';
import 'package:app/features/dicionario/dicionario/ui/dicionario_view.dart';
import 'package:app/features/dicionario/dicionario/ui/dicionario_viewmodel.dart';
import 'package:app/features/dicionario/dicionario/use_case/dicionario_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

final _abegaoJson = <String, dynamic>{
  'dverId': 430,
  'dverChave': 'abegão:1',
  'dverPalavra': 'Abegão',
  'dverLetra': 'A',
  'dverHomonimo': 1,
  'dverPronuncia': null,
  'dverEtimologia': '(Do lat. hyp. _pecudonem_, de _pecus_, gado)',
  'dverEtimologiaOrigem': 'lat',
  'dverAsterisco': false,
  'dverChaveta': false,
  'acepcoes': [
    {
      'daceId': 487,
      'daceSeq': 2,
      'daceClasse': null,
      'daceDefinicao': 'Segundo sentido.',
      'daceAsterisco': false,
      'usos': <Map<String, dynamic>>[],
      'remissoes': <Map<String, dynamic>>[],
    },
    {
      'daceId': 486,
      'daceSeq': 1,
      'daceClasse': 'm.',
      'daceDefinicao': 'Aquelle que trata de abegoaria.\nFeitor de herdade ou quinta.',
      'daceAsterisco': false,
      'usos': [
        {'dusoTipo': 'registro', 'dusoTexto': 'Prov.'},
      ],
      'remissoes': [
        {'dremTermo': 'abegoaria', 'dverId': 433},
        {'dremTermo': 'inexistente', 'dverId': null},
      ],
    },
  ],
};

final _abegao1 = DicionarioVerbeteModel.fromJson(_abegaoJson);

const _abegao2 = DicionarioVerbeteModel(
  dverId: 431,
  dverPalavra: 'Abegão',
  dverHomonimo: 2,
  acepcoes: [DicionarioAcepcaoModel(daceId: 488, daceSeq: 1, daceClasse: 'adj.', daceDefinicao: 'Outro abegão.')],
);

const _abegoaria = DicionarioVerbeteModel(
  dverId: 433,
  dverPalavra: 'Abegoaria',
  acepcoes: [DicionarioAcepcaoModel(daceId: 490, daceSeq: 1, daceClasse: 'f.', daceDefinicao: 'Casa do abegão.')],
);

const _buscaAbegao = DicionarioBuscaModel(
  dverId: 430,
  dverPalavra: 'Abegão',
  dverHomonimo: 1,
  dverLetra: 'A',
  daceClasse: 'm.',
  daceDefinicao: 'Aquelle que trata de _abegoaria_.\nFeitor.',
  semelhanca: 0.5,
);

const _buscaAbegoaria = DicionarioBuscaModel(dverId: 433, dverPalavra: 'Abegoaria', dverLetra: 'A');

/// Dicionário em memória: palavra igual sem acento/maiúsculas; busca pelo começo.
class _FakeDicionarioRepository implements DicionarioRepository {
  final verbetes = <DicionarioVerbeteModel>[_abegao2, _abegao1, _abegoaria];
  final busca = <DicionarioBuscaModel>[_buscaAbegao, _buscaAbegoaria];
  final buscas = <(String, int)>[];
  final palavras = <String>[];
  Exception? erroBusca;
  Exception? erroPalavra;

  static String _chave(String s) => s.toLowerCase().replaceAll('ã', 'a');

  @override
  Future<Result<List<DicionarioBuscaModel>>> buscar(String texto, {required int limite}) async {
    buscas.add((texto, limite));
    final e = erroBusca;
    if (e != null) return Result.error(e);
    return Result.ok([
      for (final b in busca)
        if (_chave(b.dverPalavra).startsWith(_chave(texto))) b,
    ]);
  }

  @override
  Future<Result<List<DicionarioVerbeteModel>>> palavra(String palavra) async {
    palavras.add(palavra);
    final e = erroPalavra;
    if (e != null) return Result.error(e);
    return Result.ok([
      for (final v in verbetes)
        if (_chave(v.dverPalavra) == _chave(palavra)) v,
    ]);
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

void main() {
  late _FakeDicionarioRepository repository;

  setUp(() => repository = _FakeDicionarioRepository());

  DicionarioUseCase criarUseCase() => DicionarioUseCase(dicionarioRepository: repository);

  DicionarioViewmodel criar() => DicionarioViewmodel(dicionarioUseCase: criarUseCase());

  Future<void> montar(WidgetTester tester, DicionarioViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: DicionarioView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('models', () {
    test('DicionarioVerbeteModel.fromJson lê verbete, acepções, usos e remissões', () {
      expect(_abegao1.dverId, 430);
      expect(_abegao1.dverHomonimo, 1);
      expect(_abegao1.dverPronuncia, isNull);
      expect(_abegao1.dverEtimologiaOrigem, 'lat');
      expect(_abegao1.acepcoes, hasLength(2));
      final primeira = _abegao1.acepcoes.last;
      expect(primeira.daceClasse, 'm.');
      expect(primeira.usos.single.dusoTexto, 'Prov.');
      expect(primeira.remissoes.first.dverId, 433);
      expect(primeira.remissoes.last.dverId, isNull);
    });

    test('DicionarioVerbeteModel.fromJson aceita snake_case e listas ausentes', () {
      final v = DicionarioVerbeteModel.fromJson({'dver_id': '7', 'dver_palavra': 'Graça'});
      expect(v.dverId, 7);
      expect(v.dverPalavra, 'Graça');
      expect(v.acepcoes, isEmpty);
      expect(v.dverChaveta, isFalse);
    });

    test('DicionarioVerbeteModel.fromJson rejeita campos inválidos', () {
      expect(() => DicionarioVerbeteModel.fromJson({'dverId': 1}), throwsFormatException);
      expect(
        () => DicionarioVerbeteModel.fromJson({'dverId': 1, 'dverPalavra': 'a', 'acepcoes': 'x'}),
        throwsFormatException,
      );
    });

    test('DicionarioBuscaModel.fromJson lê semelhança como número', () {
      final b = DicionarioBuscaModel.fromJson({
        'dverId': 430,
        'dverPalavra': 'Abegão',
        'dverHomonimo': null,
        'daceClasse': null,
        'semelhanca': 1,
      });
      expect(b.semelhanca, 1.0);
      expect(b.dverHomonimo, isNull);
      expect(b.toJson()['dverPalavra'], 'Abegão');
    });
  });

  group('DicionarioUseCase', () {
    test('buscar só chama a API a partir de 2 caracteres, normalizado e com o limite', () async {
      final useCase = criarUseCase();
      expect(await useCase.buscar(' a '), isA<Ok<List<DicionarioBuscaModel>>>());
      expect(repository.buscas, isEmpty);

      final result = await useCase.buscar('  abeg   ');
      expect((result as Ok<List<DicionarioBuscaModel>>).value, hasLength(2));
      expect(repository.buscas.single, ('abeg', DicionarioUseCase.buscaLimite));
    });

    test('texto acima de 64 caracteres não chama a API', () async {
      final useCase = criarUseCase();
      final result = await useCase.consultar('a' * 65);
      expect(((result as Error).error as HandledException).message, 'textoBuscaMuitoLongo');
      expect(repository.palavras, isEmpty);
    });

    test('consultar ordena homônimos; palavra inexistente traz as semelhantes', () async {
      final useCase = criarUseCase();
      final achou = (await useCase.consultar('abegao')) as Ok<DicionarioConsulta>;
      expect(achou.value.encontrada, isTrue);
      expect(achou.value.verbetes.map((v) => v.dverHomonimo), [1, 2]);
      expect(repository.buscas, isEmpty);

      final naoAchou = (await useCase.consultar('abeg')) as Ok<DicionarioConsulta>;
      expect(naoAchou.value.encontrada, isFalse);
      expect(naoAchou.value.sugestoes.map((s) => s.dverPalavra), ['Abegão', 'Abegoaria']);
    });

    test('consultar repassa o erro da API', () async {
      repository.erroPalavra = HttpServiceException(message: 'erroGeralApi');
      final result = await criarUseCase().consultar('abegao');
      expect(DicionarioUseCase.mensagemErro((result as Error).error), 'erroGeralApi');
    });

    test('textos: itálico, resumo, título com homônimo, acepções e remissões', () {
      expect(DicionarioUseCase.trechos('(Do lat. _pecus_, gado)'), [
        (texto: '(Do lat. ', italico: false),
        (texto: 'pecus', italico: true),
        (texto: ', gado)', italico: false),
      ]);
      expect(DicionarioUseCase.resumo(_buscaAbegao.daceDefinicao), 'Aquelle que trata de abegoaria. Feitor.');
      expect(DicionarioUseCase.resumo('  '), isNull);
      expect(DicionarioUseCase.titulo('Abegão', 1), 'Abegão¹');
      expect(DicionarioUseCase.titulo('Abegão', 12), 'Abegão¹²');
      expect(DicionarioUseCase.titulo('Abegoaria', null), 'Abegoaria');
      expect(DicionarioUseCase.acepcoes(_abegao1).map((a) => a.daceSeq), [1, 2]);
      expect(DicionarioUseCase.remissoes(_abegao1.acepcoes.last), [
        (termo: 'abegoaria', navegavel: true),
        (termo: 'inexistente', navegavel: false),
      ]);
    });
  });

  group('DicionarioViewmodel', () {
    test('buscar mostra sugestões; consultar troca pela consulta; limpar volta ao início', () async {
      final vm = criar();
      expect(vm.exibicao, DicionarioExibicao.inicio);

      await vm.buscar('abe');
      expect(vm.exibicao, DicionarioExibicao.sugestoes);
      expect(vm.sugestoes, hasLength(2));

      await vm.consultarCommand.execute('Abegão');
      expect(vm.exibicao, DicionarioExibicao.consulta);
      expect(vm.consulta?.verbetes, hasLength(2));
      expect(vm.sugestoes, isNull);

      vm.limpar();
      expect(vm.exibicao, DicionarioExibicao.inicio);
      expect(vm.consulta, isNull);
    });

    test('digitar descarta a consulta em andamento', () async {
      final vm = criar();
      final consulta = vm.consultarCommand.execute('abegao');
      await vm.buscar('abegoa');
      await consulta;
      expect(vm.exibicao, DicionarioExibicao.sugestoes);
      expect(vm.consulta, isNull);
      expect(vm.sugestoes?.single.dverPalavra, 'Abegoaria');
    });

    test('erro da consulta fica em erroConsulta e repetirConsulta refaz', () async {
      final vm = criar();
      repository.erroPalavra = HttpServiceException(message: 'erroGeralApi');
      await vm.consultarCommand.execute('abegao');
      expect(vm.erroConsulta, 'erroGeralApi');

      repository.erroPalavra = null;
      await vm.repetirConsulta();
      expect(vm.erroConsulta, isNull);
      expect(vm.consulta?.encontrada, isTrue);
      expect(repository.palavras, ['abegao', 'abegao']);
    });

    test('erro da busca fica em erroBusca', () async {
      final vm = criar();
      repository.erroBusca = HandledException(message: 'respostaApiInvalida');
      await vm.buscar('abe');
      expect(vm.erroBusca, 'respostaApiInvalida');
      expect(vm.sugestoes, isEmpty);
    });
  });

  group('DicionarioView', () {
    testWidgets('início, sugestões ao digitar e verbete ao tocar', (tester) async {
      await montar(tester, criar());
      expect(find.text('dicionario'), findsOneWidget);
      expect(find.text('dicionarioInicio'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abe');
      await tester.pump(DicionarioView.esperaBusca);
      await tester.pumpAndSettle();
      expect(find.textContaining('Abegão¹'), findsOneWidget);
      expect(find.textContaining('Abegoaria'), findsOneWidget);
      expect(find.text('Aquelle que trata de abegoaria. Feitor.'), findsOneWidget);

      await tester.tap(find.textContaining('Abegão¹'));
      await tester.pumpAndSettle();
      expect(repository.palavras, ['Abegão']);
      expect(find.text('Abegão¹'), findsOneWidget);
      expect(find.text('Abegão²'), findsOneWidget);
      expect(find.text('Prov.'), findsOneWidget);
      expect(find.textContaining('vejaTambem'), findsOneWidget);
      expect(tester.widget<ActionChip>(find.widgetWithText(ActionChip, 'inexistente')).onPressed, isNull);

      await tester.dragUntilVisible(find.text('dicionarioFonte'), find.byType(ListView), const Offset(0, -300));
      expect(find.text('dicionarioFonte'), findsOneWidget);
    });

    testWidgets('remissão consulta o termo e o coloca no campo', (tester) async {
      await montar(tester, criar());
      await tester.enterText(find.byType(TextField), 'abegao');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'abegoaria'));
      await tester.pumpAndSettle();
      expect(repository.palavras.last, 'abegoaria');
      expect(find.text('Casa do abegão.'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'abegoaria');
    });

    testWidgets('palavra não encontrada mostra as semelhantes', (tester) async {
      await montar(tester, criar());
      await tester.enterText(find.byType(TextField), 'abeg');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('palavraNaoEncontrada: "abeg"'), findsOneWidget);
      expect(find.text('palavrasSemelhantes'), findsOneWidget);
      expect(find.textContaining('Abegoaria'), findsOneWidget);
    });

    testWidgets('busca sem resultado e limpar', (tester) async {
      await montar(tester, criar());
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(DicionarioView.esperaBusca);
      await tester.pumpAndSettle();
      expect(find.text('nenhumaPalavraEncontrada'), findsOneWidget);

      await tester.tap(find.byTooltip('limpar'));
      await tester.pumpAndSettle();
      expect(find.text('dicionarioInicio'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    });

    testWidgets('erro da consulta com tentar novamente', (tester) async {
      repository.erroPalavra = HttpServiceException(message: 'erroGeralApi');
      await montar(tester, criar());
      await tester.enterText(find.byType(TextField), 'abegao');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erroPalavra = null;
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Abegão¹'), findsOneWidget);
    });
  });
}
