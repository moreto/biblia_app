import 'package:app/data/model/comunidade/comunidade_denominacao_model.dart';
import 'package:app/data/model/comunidade/comunidade_model.dart';
import 'package:app/data/model/comunidade/comunidade_tipo_model.dart';
import 'package:app/features/comunidade/repository/comunidade_repository.dart';
import 'package:app/features/comunidade/ui/comunidade_view.dart';
import 'package:app/features/comunidade/ui/comunidade_viewmodel.dart';
import 'package:app/features/comunidade/use_case/comunidade_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _usuario = 7;

const _matriz = ComunidadeModel(comuId: 1, comuNome: 'Paróquia Matriz', ctipId: 1, cdenId: 2, usuaId: _usuario);
const _capela = ComunidadeModel(comuId: 2, comuNome: 'capela São José', ctipId: 9, usuaId: _usuario);
const _grupo = ComunidadeModel(comuId: 3, comuNome: 'Grupo de Oração', usuaId: _usuario);

/// Comunidades em ordem de respostas (como chamadas sucessivas); tipos e denominações fixos ou com erro.
class _FakeComunidadeRepository implements ComunidadeRepository {
  _FakeComunidadeRepository(this.respostas);

  final List<Result<List<ComunidadeModel>>> respostas;
  final usuarios = <int>[];
  int chamadas = 0;
  Exception? erroTipos;
  Exception? erroDenominacoes;

  @override
  Future<Result<List<ComunidadeModel>>> comunidadesDoUsuario(int usuaId) async {
    usuarios.add(usuaId);
    return respostas[chamadas++ % respostas.length];
  }

  @override
  Future<Result<List<ComunidadeTipoModel>>> tipos() async => erroTipos != null
      ? Result.error(erroTipos!)
      : const Result.ok([
          ComunidadeTipoModel(ctipId: 1, ctipNome: 'Paróquia'),
          ComunidadeTipoModel(ctipId: 2, ctipNome: 'Capela'),
        ]);

  @override
  Future<Result<List<ComunidadeDenominacaoModel>>> denominacoes() async => erroDenominacoes != null
      ? Result.error(erroDenominacoes!)
      : const Result.ok([ComunidadeDenominacaoModel(cdenId: 2, cdenNome: 'Católica')]);
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
  ComunidadeUseCase criarUseCase(_FakeComunidadeRepository repository, {int? usuario = _usuario}) =>
      ComunidadeUseCase(comunidadeRepository: repository, usuarioLogado: () => usuario);

  ComunidadeViewmodel criar(_FakeComunidadeRepository repository) =>
      ComunidadeViewmodel(comunidadeUseCase: criarUseCase(repository));

  Future<void> montar(WidgetTester tester, ComunidadeViewmodel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: ComunidadeView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ComunidadeModel', () {
    test('fromJson aceita camelCase e snake_case com opcionais nulos', () {
      final camel = ComunidadeModel.fromJson({'comuId': 1, 'comuNome': 'A', 'ctipId': 2, 'cdenId': '3', 'usuaId': 4});
      expect((camel.comuId, camel.comuNome, camel.ctipId, camel.cdenId, camel.usuaId), (1, 'A', 2, 3, 4));

      final snake = ComunidadeModel.fromJson({'comu_id': 5, 'comu_nome': 'B', 'ctip_id': null});
      expect((snake.comuId, snake.comuNome, snake.ctipId, snake.cdenId), (5, 'B', null, null));
    });

    test('fromJson sem nome lança FormatException', () {
      expect(() => ComunidadeModel.fromJson({'comuId': 1}), throwsFormatException);
    });
  });

  group('ComunidadeUseCase', () {
    test('a primeira aba é "Minhas comunidades"', () {
      expect(criarUseCase(_FakeComunidadeRepository([const Result.ok([])])).abas.first, ComunidadeAba.minhas);
    });

    test('lista as comunidades do usuário logado por nome, com tipo e denominação', () async {
      final repository = _FakeComunidadeRepository([
        const Result.ok([_matriz, _grupo, _capela]),
      ]);
      final lista = (await criarUseCase(repository).minhasComunidades() as Ok<List<ComunidadeResumo>>).value;

      expect(repository.usuarios, [_usuario]);
      expect(lista.map((c) => c.comunidade.comuId), [2, 3, 1], reason: 'sem diferenciar maiúsculas');
      expect(ComunidadeUseCase.descricao(lista[2]), 'Paróquia · Católica');
      expect(ComunidadeUseCase.descricao(lista[0]), isNull, reason: 'tipo 9 não existe');
      expect(ComunidadeUseCase.descricao(lista[1]), isNull);
    });

    test('falha em tipos ou denominações não impede a lista', () async {
      final repository = _FakeComunidadeRepository([
        const Result.ok([_matriz]),
      ])..erroTipos = HttpServiceException(message: 'erroGeralApi', code: 500);
      final lista = (await criarUseCase(repository).minhasComunidades() as Ok<List<ComunidadeResumo>>).value;

      expect(ComunidadeUseCase.descricao(lista.single), 'Católica');
    });

    test('404 registroNaoEncontrado vira lista vazia e outros erros são repassados', () async {
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      final repository = _FakeComunidadeRepository([
        Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
        Result.error(erro),
      ]);
      final useCase = criarUseCase(repository);

      expect((await useCase.minhasComunidades() as Ok<List<ComunidadeResumo>>).value, isEmpty);
      expect((await useCase.minhasComunidades() as Error).error, same(erro));
    });

    test('sem usuário logado devolve headerInvalido sem chamar a API', () async {
      final repository = _FakeComunidadeRepository([const Result.ok([])]);
      final result = await criarUseCase(repository, usuario: null).minhasComunidades();

      expect(((result as Error).error as HandledException).message, 'headerInvalido');
      expect(repository.usuarios, isEmpty);
    });
  });

  group('ComunidadeViewmodel', () {
    test('carrega "Minhas comunidades" ao ser criado', () async {
      final viewModel = criar(
        _FakeComunidadeRepository([
          const Result.ok([_matriz]),
        ]),
      );
      await pumpEventQueue();

      expect(viewModel.minhasCommand.completed, isTrue);
      expect(viewModel.minhas?.single.comunidade.comuNome, 'Paróquia Matriz');
    });

    test('erro na atualização mantém a última lista', () async {
      final viewModel = criar(
        _FakeComunidadeRepository([
          const Result.ok([_matriz]),
          Result.error(HttpServiceException(message: 'erroGeralApi', code: 500)),
        ]),
      );
      await pumpEventQueue();
      await viewModel.minhasCommand.execute();

      expect(viewModel.minhasCommand.error, isTrue);
      expect(viewModel.minhas, hasLength(1));
    });
  });

  group('ComunidadeView', () {
    testWidgets('mostra a aba "Minhas comunidades" com as comunidades', (tester) async {
      await montar(
        tester,
        criar(
          _FakeComunidadeRepository([
            const Result.ok([_matriz, _capela]),
          ]),
        ),
      );

      expect(find.text('comunidades'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'minhasComunidades'), findsOneWidget);
      expect(find.text('Paróquia Matriz'), findsOneWidget);
      expect(find.text('Paróquia · Católica'), findsOneWidget);
      expect(find.text('capela São José'), findsOneWidget);
    });

    testWidgets('lista vazia mostra nenhumaComunidadeCadastrada', (tester) async {
      await montar(tester, criar(_FakeComunidadeRepository([const Result.ok([])])));
      expect(find.text('nenhumaComunidadeCadastrada'), findsOneWidget);
    });

    testWidgets('falha no primeiro carregamento mostra a mensagem e tenta novamente', (tester) async {
      await montar(
        tester,
        criar(
          _FakeComunidadeRepository([
            Result.error(HttpServiceException(message: 'erroGeralApi', code: 500)),
            const Result.ok([_grupo]),
          ]),
        ),
      );

      expect(find.text('erroGeralApi'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Grupo de Oração'), findsOneWidget);
    });

    testWidgets('falha na atualização mantém a lista e mostra SnackBar', (tester) async {
      await montar(
        tester,
        criar(
          _FakeComunidadeRepository([
            const Result.ok([_grupo]),
            Result.error(HandledException(message: 'formatoComunidadeInvalido')),
          ]),
        ),
      );

      await tester.tap(find.byTooltip('atualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Grupo de Oração'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'formatoComunidadeInvalido'), findsOneWidget);
    });
  });
}
