import 'package:app/data/model/oracao/oracao_model.dart';
import 'package:app/features/dashboard/widgets/oracao/repository/oracao_repository.dart';
import 'package:app/features/dashboard/widgets/oracao/ui/oracao_view.dart';
import 'package:app/features/dashboard/widgets/oracao/ui/oracao_viewmodel.dart';
import 'package:app/features/dashboard/widgets/oracao/use_case/oracao_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

/// Devolve, em ordem, as respostas configuradas (como sorteios sucessivos de `GET /v1/oracao/aleatoria`).
class _FakeOracaoRepository implements OracaoRepository {
  _FakeOracaoRepository(this.respostas);

  final List<Result<OracaoModel>> respostas;
  int chamadas = 0;

  @override
  Future<Result<OracaoModel>> aleatoria() async => respostas[chamadas++ % respostas.length];
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

const _paiNosso = OracaoModel(oracId: 1, oracNome: 'Pai Nosso', oracTexto: 'Pai nosso que estais no céu');
const _aveMaria = OracaoModel(oracId: 2, oracNome: 'Ave Maria', oracTexto: 'Ave Maria, cheia de graça');
final _longa = OracaoModel(oracId: 3, oracNome: 'Credo', oracTexto: List.filled(80, 'Creio em Deus Pai').join(' '));

void main() {
  OracaoViewmodel criar(List<Result<OracaoModel>> respostas) =>
      OracaoViewmodel(oracaoUseCase: OracaoUseCase(oracaoRepository: _FakeOracaoRepository(respostas)));

  Future<void> montar(WidgetTester tester, OracaoViewmodel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(child: OracaoView(viewModel: viewModel)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OracaoUseCase', () {
    test('repassa a oração sorteada', () async {
      final useCase = OracaoUseCase(oracaoRepository: _FakeOracaoRepository([Result.ok(_paiNosso)]));
      expect((await useCase.aleatoria() as Ok<OracaoModel>).value.oracNome, 'Pai Nosso');
    });

    test('404 registroNaoEncontrado vira nenhumaOracaoCadastrada', () async {
      final useCase = OracaoUseCase(
        oracaoRepository: _FakeOracaoRepository([
          Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
        ]),
      );
      expect((await useCase.aleatoria() as Error).error, isA<HandledException>());
      expect(((await useCase.aleatoria() as Error).error as HandledException).message, 'nenhumaOracaoCadastrada');
    });

    test('outros erros são repassados sem alteração', () async {
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      final useCase = OracaoUseCase(oracaoRepository: _FakeOracaoRepository([Result.error(erro)]));
      expect((await useCase.aleatoria() as Error).error, same(erro));
    });
  });

  group('OracaoModel', () {
    test('lê o JSON da API em camelCase', () {
      final model = OracaoModel.fromJson({
        'oracId': 4,
        'oracNome': 'Glória',
        'oracTexto': 'Glória ao Pai',
        'createdAt': '',
      });
      expect(model.oracId, 4);
      expect(model.oracNome, 'Glória');
      expect(model.oracTexto, 'Glória ao Pai');
    });
  });

  group('OracaoViewmodel', () {
    test('carrega uma oração ao ser criado e sorteia outra no comando', () async {
      final viewModel = criar([Result.ok(_paiNosso), Result.ok(_aveMaria)]);
      await pumpEventQueue();
      expect(viewModel.oracao?.oracId, 1);

      await viewModel.aleatoriaCommand.execute();
      expect(viewModel.oracao?.oracId, 2);
    });

    test('erro em novo sorteio mantém a oração atual', () async {
      final viewModel = criar([Result.ok(_paiNosso), Result.error(HandledException(message: 'erroApi'))]);
      await pumpEventQueue();
      await viewModel.aleatoriaCommand.execute();
      expect(viewModel.aleatoriaCommand.error, isTrue);
      expect(viewModel.oracao?.oracId, 1);
    });

    test('novo sorteio recolhe o texto', () async {
      final viewModel = criar([Result.ok(_paiNosso)]);
      await pumpEventQueue();
      viewModel.alternarExpandida();
      expect(viewModel.expandida, isTrue);
      await viewModel.aleatoriaCommand.execute();
      expect(viewModel.expandida, isFalse);
    });
  });

  group('OracaoView', () {
    testWidgets('mostra a oração e sorteia outra ao tocar em "Outra oração"', (tester) async {
      await montar(tester, criar([Result.ok(_paiNosso), Result.ok(_aveMaria)]));

      expect(find.text('Pai Nosso'), findsOneWidget);
      expect(find.text('Pai nosso que estais no céu'), findsOneWidget);
      // texto curto: sem "Ler mais"
      expect(find.text('lerMais'), findsNothing);

      await tester.tap(find.text('outraOracao'));
      await tester.pumpAndSettle();
      expect(find.text('Ave Maria'), findsOneWidget);
    });

    testWidgets('texto longo começa recolhido e expande em "Ler mais"', (tester) async {
      await montar(tester, criar([Result.ok(_longa)]));

      Text texto() => tester.widget<Text>(find.text(_longa.oracTexto));
      expect(texto().maxLines, OracaoView.linhasRecolhido);

      await tester.tap(find.text('lerMais'));
      await tester.pumpAndSettle();
      expect(texto().maxLines, isNull);
      expect(find.text('lerMenos'), findsOneWidget);
    });

    testWidgets('sem orações cadastradas mostra a mensagem e tenta novamente', (tester) async {
      final viewModel = criar([
        Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
        Result.ok(_paiNosso),
      ]);
      await montar(tester, viewModel);

      expect(find.text('nenhumaOracaoCadastrada'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Pai Nosso'), findsOneWidget);
    });

    testWidgets('erro em novo sorteio mantém a oração e avisa no SnackBar', (tester) async {
      await montar(tester, criar([Result.ok(_paiNosso), Result.error(HandledException(message: 'erroApi'))]));

      await tester.tap(find.text('outraOracao'));
      await tester.pumpAndSettle();
      expect(find.text('Pai Nosso'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'erroApi'), findsOneWidget);
    });
  });
}
