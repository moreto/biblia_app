import 'package:app/data/model/biblia/renomado_model.dart';
import 'package:app/features/biblia/renomado/repository/renomado_repository.dart';
import 'package:app/features/biblia/renomado/ui/renomado_view.dart';
import 'package:app/features/biblia/renomado/ui/renomado_viewmodel.dart';
import 'package:app/features/biblia/renomado/use_case/renomado_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

/// Devolve, em ordem, as respostas configuradas (como chamadas sucessivas de `GET /v1/renomado`).
class _FakeRenomadoRepository implements RenomadoRepository {
  _FakeRenomadoRepository(this.respostas);

  final List<Result<List<RenomadoModel>>> respostas;
  int chamadas = 0;

  @override
  Future<Result<List<RenomadoModel>>> getAll() async => respostas[chamadas++ % respostas.length];
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

const _agostinho = RenomadoModel(renoId: 1, renoNome: 'Santo Agostinho', renoTexto: 'Bispo de Hipona', renoSeq: 2);
const _teresa = RenomadoModel(renoId: 2, renoNome: 'Santa Teresa', renoSeq: 1);
const _francisco = RenomadoModel(renoId: 3, renoNome: 'São Francisco', renoTexto: '   ');

void main() {
  RenomadoViewmodel criar(List<Result<List<RenomadoModel>>> respostas) =>
      RenomadoViewmodel(renomadoUseCase: RenomadoUseCase(renomadoRepository: _FakeRenomadoRepository(respostas)));

  Future<void> montar(WidgetTester tester, RenomadoViewmodel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: RenomadoView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RenomadoModel', () {
    test('fromJson aceita camelCase e snake_case com opcionais nulos', () {
      final camel = RenomadoModel.fromJson({'renoId': 1, 'renoNome': 'A', 'renoTexto': 't', 'renoSeq': '3'});
      expect((camel.renoId, camel.renoNome, camel.renoTexto, camel.renoSeq), (1, 'A', 't', 3));

      final snake = RenomadoModel.fromJson({'reno_id': 2, 'reno_nome': 'B', 'reno_texto': null, 'reno_seq': null});
      expect((snake.renoId, snake.renoNome, snake.renoTexto, snake.renoSeq), (2, 'B', null, null));
    });

    test('fromJson sem nome lança FormatException', () {
      expect(() => RenomadoModel.fromJson({'renoId': 1}), throwsFormatException);
    });
  });

  group('RenomadoUseCase', () {
    test('ordena por sequência (sem sequência por último), nome e id e normaliza os textos', () async {
      final useCase = RenomadoUseCase(
        renomadoRepository: _FakeRenomadoRepository([
          const Result.ok([
            _francisco,
            RenomadoModel(renoId: 4, renoNome: '  abraão ', renoSeq: null),
            _agostinho,
            _teresa,
          ]),
        ]),
      );

      final lista = (await useCase.listar() as Ok<List<RenomadoModel>>).value;
      expect(lista.map((r) => r.renoNome), ['Santa Teresa', 'Santo Agostinho', 'abraão', 'São Francisco']);
      expect(lista.last.renoTexto, isNull, reason: 'texto em branco vira nulo');
    });

    test('404 registroNaoEncontrado vira lista vazia', () async {
      final useCase = RenomadoUseCase(
        renomadoRepository: _FakeRenomadoRepository([
          Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
        ]),
      );
      expect((await useCase.listar() as Ok<List<RenomadoModel>>).value, isEmpty);
    });

    test('outros erros são repassados sem alteração', () async {
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      final useCase = RenomadoUseCase(renomadoRepository: _FakeRenomadoRepository([Result.error(erro)]));
      expect((await useCase.listar() as Error).error, same(erro));
    });
  });

  group('RenomadoViewmodel', () {
    test('carrega a lista ao ser criado', () async {
      final viewModel = criar([
        const Result.ok([_agostinho, _teresa]),
      ]);
      await pumpEventQueue();

      expect(viewModel.listarCommand.completed, isTrue);
      expect(viewModel.renomados?.map((r) => r.renoId), [2, 1]);
    });

    test('erro na atualização mantém a última lista', () async {
      final viewModel = criar([
        const Result.ok([_agostinho]),
        Result.error(HttpServiceException(message: 'erroGeralApi', code: 500)),
      ]);
      await pumpEventQueue();
      await viewModel.listarCommand.execute();

      expect(viewModel.listarCommand.error, isTrue);
      expect(viewModel.renomados?.single.renoNome, 'Santo Agostinho');
    });
  });

  group('RenomadoView', () {
    testWidgets('lista os renomados com nome e texto', (tester) async {
      await montar(
        tester,
        criar([
          const Result.ok([_agostinho, _teresa]),
        ]),
      );

      expect(find.text('renomados'), findsOneWidget);
      expect(find.text('Santo Agostinho'), findsOneWidget);
      expect(find.text('Bispo de Hipona'), findsOneWidget);
      expect(find.text('Santa Teresa'), findsOneWidget);
    });

    testWidgets('lista vazia mostra nenhumRenomadoCadastrado', (tester) async {
      await montar(tester, criar([const Result.ok([])]));
      expect(find.text('nenhumRenomadoCadastrado'), findsOneWidget);
    });

    testWidgets('falha no primeiro carregamento mostra a mensagem e tenta novamente', (tester) async {
      await montar(
        tester,
        criar([
          Result.error(HttpServiceException(message: 'erroGeralApi', code: 500)),
          const Result.ok([_teresa]),
        ]),
      );

      expect(find.text('erroGeralApi'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Santa Teresa'), findsOneWidget);
    });

    testWidgets('falha na atualização mantém a lista e mostra SnackBar', (tester) async {
      await montar(
        tester,
        criar([
          const Result.ok([_teresa]),
          Result.error(HandledException(message: 'formatoRenomadoInvalido')),
        ]),
      );

      await tester.tap(find.byTooltip('atualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Santa Teresa'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'formatoRenomadoInvalido'), findsOneWidget);
    });
  });
}
