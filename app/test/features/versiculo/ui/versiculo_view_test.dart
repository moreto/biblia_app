import 'package:app/config/icons_map.dart';
import 'package:app/data/model/versiculo/versiculo_model.dart';
import 'package:app/features/dashboard/widgets/versiculo/repository/versiculo_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo/ui/versiculo_view.dart';
import 'package:app/features/dashboard/widgets/versiculo/ui/versiculo_viewmodel.dart';
import 'package:app/features/dashboard/widgets/versiculo/use_case/versiculo_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

/// Devolve, em ordem, as respostas configuradas (como sorteios sucessivos de `GET /v1/versiculo/aleatorio`).
class _FakeVersiculoRepository implements VersiculoRepository {
  _FakeVersiculoRepository(this.respostas);

  final List<Result<VersiculoModel>> respostas;
  int chamadas = 0;

  @override
  Future<Result<VersiculoModel>> aleatorio() async => respostas[chamadas++ % respostas.length];
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

const _joao = VersiculoModel(
  versId: 26137,
  versNumero: 16,
  versTexto: 'Porque Deus amou o mundo de tal maneira',
  capiNumero: 3,
  livrId: 43,
  livrNome: 'João',
  livrAbrev: 'Jo',
  testNome: 'Novo Testamento',
  versaId: 3,
  versaCodigo: 'ARC',
  versaNome: 'Almeida Revista e Corrigida',
  versReferencia: 'João 3:16 (ARC)',
);

const _genesis = VersiculoModel(
  versId: 1,
  versNumero: 1,
  versTexto: 'No princípio criou Deus os céus e a terra',
  capiNumero: 1,
  livrId: 1,
  livrNome: 'Gênesis',
  livrAbrev: 'Gn',
  testNome: 'Antigo Testamento',
  versaId: 3,
  versaCodigo: 'ARC',
  versaNome: 'Almeida Revista e Corrigida',
  versReferencia: 'Gênesis 1:1 (ARC)',
);

void main() {
  VersiculoViewmodel criar(List<Result<VersiculoModel>> respostas) =>
      VersiculoViewmodel(versiculoUseCase: VersiculoUseCase(versiculoRepository: _FakeVersiculoRepository(respostas)));

  Future<void> montar(WidgetTester tester, VersiculoViewmodel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(child: VersiculoView(viewModel: viewModel)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('VersiculoUseCase', () {
    test('repassa o versículo sorteado', () async {
      final useCase = VersiculoUseCase(versiculoRepository: _FakeVersiculoRepository([Result.ok(_joao)]));
      expect((await useCase.aleatorio() as Ok<VersiculoModel>).value.versReferencia, 'João 3:16 (ARC)');
    });

    test('404 registroNaoEncontrado vira nenhumVersiculoCadastrado', () async {
      final useCase = VersiculoUseCase(
        versiculoRepository: _FakeVersiculoRepository([
          Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
        ]),
      );
      final erro = (await useCase.aleatorio() as Error).error;
      expect(erro, isA<HandledException>());
      expect((erro as HandledException).message, 'nenhumVersiculoCadastrado');
    });

    test('outros erros são repassados sem alteração', () async {
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      final useCase = VersiculoUseCase(versiculoRepository: _FakeVersiculoRepository([Result.error(erro)]));
      expect((await useCase.aleatorio() as Error).error, same(erro));
    });
  });

  group('VersiculoModel', () {
    final json = {
      'testId': 2,
      'testNome': 'Novo Testamento',
      'livrId': 43,
      'livrNome': 'João',
      'livrAbrev': 'Jo',
      'capiNumero': 3,
      'versId': 26137,
      'versNumero': 16,
      'versTexto': 'Porque Deus amou o mundo',
      'versaId': 3,
      'versaCodigo': 'ARC',
      'versaNome': 'Almeida Revista e Corrigida',
      'versReferencia': 'João 3:16 (ARC)',
    };

    test('lê o JSON da API em camelCase com a referência completa', () {
      final model = VersiculoModel.fromJson(json);
      expect(model.versId, 26137);
      expect(model.livrNome, 'João');
      expect(model.capiNumero, 3);
      expect(model.versNumero, 16);
      expect(model.versaCodigo, 'ARC');
      expect(model.versReferencia, 'João 3:16 (ARC)');
      expect(model.toJson()['versReferencia'], 'João 3:16 (ARC)');
    });

    test('monta a referência quando a API não a envia', () {
      final model = VersiculoModel.fromJson({...json}..remove('versReferencia'));
      expect(model.versReferencia, 'João 3:16 (ARC)');
    });

    test('JSON sem campo obrigatório lança TypeError (vira formatoVersiculoInvalido no repository)', () {
      expect(() => VersiculoModel.fromJson({...json}..remove('versTexto')), throwsA(isA<TypeError>()));
    });
  });

  group('VersiculoViewmodel', () {
    test('carrega um versículo ao ser criado e sorteia outro no comando', () async {
      final viewModel = criar([Result.ok(_joao), Result.ok(_genesis)]);
      await pumpEventQueue();
      expect(viewModel.versiculo?.versId, 26137);

      await viewModel.aleatorioCommand.execute();
      expect(viewModel.versiculo?.versId, 1);
    });

    test('erro em novo sorteio mantém o versículo atual', () async {
      final viewModel = criar([Result.ok(_joao), Result.error(HandledException(message: 'erroApi'))]);
      await pumpEventQueue();
      await viewModel.aleatorioCommand.execute();
      expect(viewModel.aleatorioCommand.error, isTrue);
      expect(viewModel.versiculo?.versId, 26137);
    });
  });

  group('IconsMap', () {
    test('mapeia os ícones usados pelo card', () {
      for (final chave in [VersiculoView.iconeCard, VersiculoView.iconeOutro, VersiculoView.iconeTentarNovamente]) {
        expect(IconsMap.mdiIcons[chave], isNotNull, reason: chave);
      }
    });
  });

  group('VersiculoView', () {
    testWidgets('mostra texto e referência completa e sorteia outro ao tocar em "Outro versículo"', (tester) async {
      await montar(tester, criar([Result.ok(_joao), Result.ok(_genesis)]));

      expect(find.text('versiculo'), findsOneWidget);
      expect(find.text('Porque Deus amou o mundo de tal maneira'), findsOneWidget);
      expect(find.text('João 3:16 (ARC)'), findsOneWidget);
      expect(find.text('Novo Testamento · Almeida Revista e Corrigida'), findsOneWidget);

      await tester.tap(find.text('outroVersiculo'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 1:1 (ARC)'), findsOneWidget);
      expect(find.text('João 3:16 (ARC)'), findsNothing);
    });

    testWidgets('sem versículos cadastrados mostra a mensagem e tenta novamente', (tester) async {
      final viewModel = criar([
        Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
        Result.ok(_joao),
      ]);
      await montar(tester, viewModel);

      expect(find.text('nenhumVersiculoCadastrado'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('João 3:16 (ARC)'), findsOneWidget);
    });

    testWidgets('erro em novo sorteio mantém o versículo e avisa no SnackBar', (tester) async {
      await montar(tester, criar([Result.ok(_joao), Result.error(HandledException(message: 'erroApi'))]));

      await tester.tap(find.text('outroVersiculo'));
      await tester.pumpAndSettle();
      expect(find.text('João 3:16 (ARC)'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'erroApi'), findsOneWidget);
    });
  });
}
