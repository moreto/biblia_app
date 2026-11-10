import 'package:app/data/model/funcionalidade/funcionalidade_model.dart';
import 'package:app/features/access/home/widgets/funcionalidade/repository/funcionalidade_repository.dart';
import 'package:app/features/access/home/widgets/funcionalidade/ui/funcionalidade_view.dart';
import 'package:app/features/access/home/widgets/funcionalidade/ui/funcionalidade_viewmodel.dart';
import 'package:app/features/access/home/widgets/funcionalidade/use_case/funcionalidade_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Devolve, em ordem, as respostas configuradas (como chamadas sucessivas de `GET /v1/funcionalidade`).
class _FakeFuncionalidadeRepository implements FuncionalidadeRepository {
  _FakeFuncionalidadeRepository(this.respostas);

  final List<Result<List<FuncionalidadeModel>>> respostas;
  int chamadas = 0;

  @override
  Future<Result<List<FuncionalidadeModel>>> listar() async => respostas[chamadas++ % respostas.length];
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

const _leitura = FuncionalidadeModel(
  funcId: 1,
  funcNome: 'Leitura Biblica',
  funcDescricao: 'Índice e leitura dos capítulos.',
  funcIcone: 'book-open-variant',
  funcAtivo: true,
  funcRota: '/biblia-leitura',
);
const _musica = FuncionalidadeModel(
  funcId: 2,
  funcNome: 'Música do Dia',
  funcDescricao: 'Card com uma música sorteada.',
  funcIcone: 'music-note',
  funcAtivo: false,
);

void main() {
  FuncionalidadeViewmodel criar(List<Result<List<FuncionalidadeModel>>> respostas) => FuncionalidadeViewmodel(
    funcionalidadeUseCase: FuncionalidadeUseCase(funcionalidadeRepository: _FakeFuncionalidadeRepository(respostas)),
  );

  Future<void> montar(WidgetTester tester, FuncionalidadeViewmodel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(child: FuncionalidadeView(viewModel: viewModel)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('FuncionalidadeUseCase', () {
    test('repassa a lista na ordem da API', () async {
      final useCase = FuncionalidadeUseCase(
        funcionalidadeRepository: _FakeFuncionalidadeRepository([
          Result.ok([_leitura, _musica]),
        ]),
      );
      final lista = (await useCase.listar() as Ok<List<FuncionalidadeModel>>).value;
      expect(lista.map((f) => f.funcId), [1, 2]);
    });

    test('lista vazia vira nenhumaFuncionalidadeCadastrada', () async {
      final useCase = FuncionalidadeUseCase(funcionalidadeRepository: _FakeFuncionalidadeRepository([Result.ok([])]));
      expect(((await useCase.listar() as Error).error as HandledException).message, 'nenhumaFuncionalidadeCadastrada');
    });

    test('erros são repassados sem alteração', () async {
      final erro = HandledException(message: 'erroApi');
      final useCase = FuncionalidadeUseCase(
        funcionalidadeRepository: _FakeFuncionalidadeRepository([Result.error(erro)]),
      );
      expect((await useCase.listar() as Error).error, same(erro));
    });
  });

  group('FuncionalidadeModel', () {
    test('lê o JSON da API em camelCase', () {
      final model = FuncionalidadeModel.fromJson({
        'funcId': 7,
        'funcNome': 'Leitura Biblica',
        'funcDescricao': 'Índice',
        'funcIcone': 'book-open-variant',
        'funcAtivo': true,
        'funcRota': '/biblia-leitura',
        'createdAt': '',
        'updatedAt': null,
      });
      expect(model.funcId, 7);
      expect(model.funcAtivo, isTrue);
      expect(model.funcRota, '/biblia-leitura');
    });

    test('aceita descrição, ícone e rota nulos', () {
      final model = FuncionalidadeModel.fromJson({'funcId': 1, 'funcNome': 'X', 'funcAtivo': false});
      expect(model.funcDescricao, '');
      expect(model.funcIcone, '');
      expect(model.funcRota, isNull);
    });
  });

  group('FuncionalidadeViewmodel', () {
    test('carrega a lista ao ser criado', () async {
      final viewModel = criar([
        Result.ok([_leitura, _musica]),
      ]);
      await pumpEventQueue();
      expect(viewModel.funcionalidades?.length, 2);
    });
  });

  group('FuncionalidadeView', () {
    testWidgets('mostra as funcionalidades e marca as inativas como "Em breve"', (tester) async {
      await montar(
        tester,
        criar([
          Result.ok([_leitura, _musica]),
        ]),
      );

      expect(find.text('funcionalidades'), findsOneWidget);
      expect(find.text('Leitura Biblica'), findsOneWidget);
      expect(find.text('Card com uma música sorteada.'), findsOneWidget);
      expect(find.text('emBreve'), findsOneWidget);
    });

    testWidgets('lista longa rola dentro do card, com altura limitada', (tester) async {
      final lista = [
        for (var i = 1; i <= 10; i++)
          FuncionalidadeModel(funcId: i, funcNome: 'Func $i', funcDescricao: '', funcIcone: '', funcAtivo: true),
      ];
      await montar(tester, criar([Result.ok(lista)]));

      final lista0 = find.byType(SingleChildScrollView).last;
      expect(tester.getSize(lista0).height, lessThanOrEqualTo(FuncionalidadeView.alturaMaximaLista));
      expect(find.text('Func 10').hitTestable(), findsNothing);

      await tester.drag(lista0, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.text('Func 10').hitTestable(), findsOneWidget);
    });

    testWidgets('erro no carregamento mostra a mensagem e tenta novamente', (tester) async {
      await montar(
        tester,
        criar([
          Result.ok([]),
          Result.ok([_leitura]),
        ]),
      );

      expect(find.text('nenhumaFuncionalidadeCadastrada'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Leitura Biblica'), findsOneWidget);
    });
  });
}
