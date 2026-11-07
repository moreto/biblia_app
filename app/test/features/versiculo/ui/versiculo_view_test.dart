import 'package:app/config/icons_map.dart';
import 'package:app/data/model/versiculo/versiculo_model.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/dashboard/widgets/versiculo/repository/versiculo_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo/ui/versiculo_view.dart';
import 'package:app/features/dashboard/widgets/versiculo/ui/versiculo_viewmodel.dart';
import 'package:app/features/dashboard/widgets/versiculo/use_case/versiculo_usecase.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
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

/// Reações em memória do usuário de teste ([_usuario]); [erroGravacao] faz o POST/PUT falhar.
class _FakeVersiculoReacaoRepository implements VersiculoReacaoRepository {
  _FakeVersiculoReacaoRepository([List<VersiculoReacaoModel>? iniciais]) : registros = [...?iniciais];

  final List<VersiculoReacaoModel> registros;
  Exception? erroGravacao;

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId) async =>
      Result.ok(registros.where((r) => r.versId == versId).toList());

  @override
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao) async {
    if (erroGravacao case final erro?) return Result.error(erro);
    final gravada = VersiculoReacaoModel(
      vreaId: registros.length + 1,
      versId: reacao.versId,
      usuaId: _usuario,
      vreaComentario: reacao.vreaComentario,
      vreaLido: reacao.vreaLido,
    );
    registros.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao) async {
    if (erroGravacao case final erro?) return Result.error(erro);
    registros
      ..removeWhere((r) => r.vreaId == reacao.vreaId)
      ..add(reacao);
    return Result.ok(reacao);
  }
}

const _usuario = 7;

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
  VersiculoViewmodel criar(List<Result<VersiculoModel>> respostas, {_FakeVersiculoReacaoRepository? reacoes}) =>
      VersiculoViewmodel(
        versiculoUseCase: VersiculoUseCase(versiculoRepository: _FakeVersiculoRepository(respostas)),
        versiculoReacaoUseCase: VersiculoReacaoUseCase(
          versiculoReacaoRepository: reacoes ?? _FakeVersiculoReacaoRepository(),
          usuarioLogado: () => _usuario,
        ),
      );

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

    test('carrega a reação do usuário junto com o versículo', () async {
      final viewModel = criar(
        [Result.ok(_joao), Result.ok(_genesis)],
        reacoes: _FakeVersiculoReacaoRepository(const [
          VersiculoReacaoModel(vreaId: 1, versId: 26137, usuaId: _usuario, vreaLido: true),
        ]),
      );
      await pumpEventQueue();
      expect(viewModel.lido, isTrue);

      await viewModel.aleatorioCommand.execute();
      expect(viewModel.versiculo?.versId, 1);
      expect(viewModel.lido, isFalse);
    });

    test('lidoCommand marca e desmarca como lido', () async {
      final reacoes = _FakeVersiculoReacaoRepository();
      final viewModel = criar([Result.ok(_joao)], reacoes: reacoes);
      await pumpEventQueue();

      await viewModel.lidoCommand.execute('Amém');
      expect(viewModel.lido, isTrue);
      expect(viewModel.reacao?.vreaComentario, 'Amém');
      expect(reacoes.registros, hasLength(1));

      await viewModel.lidoCommand.execute(null);
      expect(viewModel.lido, isFalse);
      expect(viewModel.reacao?.vreaComentario, 'Amém');
      expect(reacoes.registros, hasLength(1));
    });
  });

  group('IconsMap', () {
    test('mapeia os ícones usados pelo card', () {
      for (final chave in [
        VersiculoView.iconeCard,
        VersiculoView.iconeOutro,
        VersiculoView.iconeTentarNovamente,
        VersiculoView.iconeLido,
        VersiculoView.iconeNaoLido,
        VersiculoView.iconeComentario,
      ]) {
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

    testWidgets('mostra a reação já gravada e desmarca ao tocar no ícone', (tester) async {
      await montar(
        tester,
        criar(
          [Result.ok(_joao)],
          reacoes: _FakeVersiculoReacaoRepository(const [
            VersiculoReacaoModel(vreaId: 1, versId: 26137, usuaId: _usuario, vreaLido: true),
          ]),
        ),
      );

      expect(find.byTooltip('desmarcarComoLido'), findsOneWidget);
      expect(find.byIcon(IconsMap.mdiIcons[VersiculoView.iconeLido]!), findsOneWidget);

      await tester.tap(find.byTooltip('desmarcarComoLido'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('marcarComoLido'), findsOneWidget);
      expect(find.byIcon(IconsMap.mdiIcons[VersiculoView.iconeNaoLido]!), findsOneWidget);
    });

    testWidgets('erro ao gravar a reação mantém o ícone e avisa no SnackBar', (tester) async {
      final reacoes = _FakeVersiculoReacaoRepository()..erroGravacao = HandledException(message: 'erroApi');
      await montar(tester, criar([Result.ok(_joao)], reacoes: reacoes));

      await tester.tap(find.byTooltip('marcarComoLido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('marcarComoLido'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'erroApi'), findsOneWidget);
    });

    testWidgets('marcar como lido pede o comentário e o mostra no card', (tester) async {
      final reacoes = _FakeVersiculoReacaoRepository();
      await montar(tester, criar([Result.ok(_joao)], reacoes: reacoes));

      await tester.tap(find.byTooltip('marcarComoLido'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Versículo que me marcou');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byTooltip('desmarcarComoLido'), findsOneWidget);
      expect(find.text('Versículo que me marcou'), findsOneWidget);
      expect(reacoes.registros.single.vreaComentario, 'Versículo que me marcou');
    });

    testWidgets('cancelar o comentário não marca como lido', (tester) async {
      final reacoes = _FakeVersiculoReacaoRepository();
      await montar(tester, criar([Result.ok(_joao)], reacoes: reacoes));

      await tester.tap(find.byTooltip('marcarComoLido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('cancelar'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('marcarComoLido'), findsOneWidget);
      expect(reacoes.registros, isEmpty);
    });

    testWidgets('mostra o comentário de uma reação já gravada', (tester) async {
      await montar(
        tester,
        criar(
          [Result.ok(_joao)],
          reacoes: _FakeVersiculoReacaoRepository(const [
            VersiculoReacaoModel(vreaId: 1, versId: 26137, usuaId: _usuario, vreaComentario: 'Amém', vreaLido: true),
          ]),
        ),
      );
      expect(find.text('Amém'), findsOneWidget);
    });
  });
}
