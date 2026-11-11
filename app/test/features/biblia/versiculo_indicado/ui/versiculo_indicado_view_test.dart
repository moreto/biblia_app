import 'package:app/data/model/biblia/versiculo_indicado_model.dart';
import 'package:app/features/biblia/versiculo_indicado/repository/versiculo_indicado_repository.dart';
import 'package:app/features/biblia/versiculo_indicado/ui/versiculo_indicado_view.dart';
import 'package:app/features/biblia/versiculo_indicado/ui/versiculo_indicado_viewmodel.dart';
import 'package:app/features/biblia/versiculo_indicado/use_case/versiculo_indicado_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

final _mateus = VersiculoIndicadoModel(
  viusId: 7,
  vindId: 8,
  indicadoEm: DateTime(2026, 11, 11, 8, 57),
  vindComentario: ' Lembrei de você ',
  versId: 54420,
  versNumero: 34,
  versTexto: 'Não andeis, pois, ansiosos pelo dia de amanhã. ',
  versaId: 8,
  versaCodigo: 'BLIVRE',
  versaNome: 'Bíblia Livre',
  livrId: 40,
  capiNumero: 6,
  livrNome: 'Mateus',
  versReferencia: 'Mateus 6:34',
  indicadorId: 1,
  indicadorNome: 'Marcelo',
  indicadorUsuario: 'mmoreto',
);

final _joao = VersiculoIndicadoModel(
  viusId: 3,
  vindId: 6,
  indicadoEm: DateTime(2026, 11, 10, 16, 8),
  versId: 1,
  versNumero: 16,
  versTexto: 'Porque Deus amou o mundo',
  versaId: 1,
  livrId: 43,
  capiNumero: 3,
  livrNome: 'João',
);

class _FakeVersiculoIndicadoRepository implements VersiculoIndicadoRepository {
  List<VersiculoIndicadoModel> recebidasLista = [_joao, _mateus];
  Exception? erro;
  int chamadas = 0;

  @override
  Future<Result<List<VersiculoIndicadoModel>>> recebidas() async {
    chamadas++;
    final e = erro;
    return e != null ? Result.error(e) : Result.ok(List.of(recebidasLista));
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
  late _FakeVersiculoIndicadoRepository repository;

  setUp(() => repository = _FakeVersiculoIndicadoRepository());

  VersiculoIndicadoViewmodel criar() => VersiculoIndicadoViewmodel(
    versiculoIndicadoUseCase: VersiculoIndicadoUseCase(versiculoIndicadoRepository: repository),
  );

  /// Monta a tela com GoRouter; a rota da leitura guarda a URL aberta em [abertas].
  Future<void> montar(WidgetTester tester, VersiculoIndicadoViewmodel viewModel, List<Uri> abertas) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.versiculoIndicado,
      routes: [
        GoRoute(
          path: Routes.versiculoIndicado,
          builder: (context, state) => VersiculoIndicadoView(viewModel: viewModel),
        ),
        GoRoute(
          path: Routes.bibliaLeitura,
          builder: (context, state) {
            abertas.add(state.uri);
            return const Scaffold(body: Text('leitura'));
          },
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

  group('VersiculoIndicadoModel', () {
    test('fromJson aceita camelCase e snake_case; data vira hora local', () {
      final camel = VersiculoIndicadoModel.fromJson({
        'viusId': 7,
        'vindId': 8,
        'indicadoEm': '2026-11-11T11:57:51.906Z',
        'versId': 1,
        'versNumero': 34,
        'versTexto': 'texto',
        'versaId': '8',
        'livrId': 40,
        'capiNumero': 6,
        'indicadorUsuario': 'mm',
      });
      expect((camel.viusId, camel.versaId, camel.indicadorUsuario), (7, 8, 'mm'));
      expect(camel.indicadoEm, DateTime.utc(2026, 11, 11, 11, 57, 51, 906).toLocal());

      final snake = VersiculoIndicadoModel.fromJson({
        'vius_id': 1,
        'vind_id': 2,
        'vers_id': 3,
        'vers_numero': 4,
        'vers_texto': 't',
        'versa_id': 5,
        'livr_id': 6,
        'capi_numero': 7,
        'vind_comentario': 'c',
      });
      expect((snake.vindComentario, snake.indicadoEm), ('c', null));
    });

    test('fromJson sem o texto do versículo lança FormatException', () {
      expect(
        () => VersiculoIndicadoModel.fromJson({
          'viusId': 1,
          'vindId': 1,
          'versId': 1,
          'versNumero': 1,
          'versaId': 1,
          'livrId': 1,
          'capiNumero': 1,
        }),
        throwsFormatException,
      );
    });
  });

  group('VersiculoIndicadoUseCase', () {
    test('mais recentes primeiro, sem data por último; 404 vira lista vazia', () async {
      final semData = VersiculoIndicadoModel(
        viusId: 1,
        vindId: 1,
        versId: 1,
        versNumero: 1,
        versTexto: 'x',
        versaId: 1,
        livrId: 1,
        capiNumero: 1,
      );
      repository.recebidasLista = [semData, _joao, _mateus];
      final useCase = VersiculoIndicadoUseCase(versiculoIndicadoRepository: repository);
      final lista = (await useCase.recebidas() as Ok<List<VersiculoIndicadoModel>>).value;
      expect(lista.map((i) => i.viusId), [7, 3, 1]);

      repository.erro = HttpServiceException(message: 'registroNaoEncontrado');
      expect((await useCase.recebidas() as Ok<List<VersiculoIndicadoModel>>).value, isEmpty);
    });

    test('textos: referência com versão, quem indicou, comentário e data', () {
      expect(VersiculoIndicadoUseCase.referencia(_mateus), 'Mateus 6:34 · BLIVRE');
      expect(VersiculoIndicadoUseCase.referencia(_joao), 'João 3:16', reason: 'sem referência da API nem versão');
      expect(VersiculoIndicadoUseCase.quemIndicou(_mateus), 'Marcelo (@mmoreto)');
      expect(VersiculoIndicadoUseCase.quemIndicou(_joao), isNull);
      expect(VersiculoIndicadoUseCase.comentario(_mateus), 'Lembrei de você');
      expect(VersiculoIndicadoUseCase.comentario(_joao), isNull);
      expect(VersiculoIndicadoUseCase.data(_mateus), '11/11/2026 08:57');
    });

    test('destino: o versículo na versão indicada', () {
      final destino = VersiculoIndicadoUseCase.destino(_mateus);
      expect(destino.toQuery(), {'versaId': '8', 'livrId': '40', 'capiNumero': '6', 'versNumero': '34'});
    });
  });

  group('VersiculoIndicadoView', () {
    testWidgets('lista as indicações e abre o versículo na leitura ao tocar', (tester) async {
      final abertas = <Uri>[];
      await montar(tester, criar(), abertas);

      expect(find.text('indicacoesRecebidas'), findsOneWidget);
      expect(find.text('Mateus 6:34 · BLIVRE'), findsOneWidget);
      expect(find.text('Lembrei de você'), findsOneWidget);
      expect(find.text('indicadoPor Marcelo (@mmoreto)'), findsOneWidget);
      expect(find.text('11/11/2026 08:57'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Mateus 6:34 · BLIVRE')).dy,
        lessThan(tester.getTopLeft(find.text('João 3:16')).dy),
        reason: 'mais recente primeiro',
      );

      await tester.tap(find.text('Mateus 6:34 · BLIVRE'));
      await tester.pumpAndSettle();
      expect(abertas.single.path, Routes.bibliaLeitura);
      expect(abertas.single.queryParameters, {'versaId': '8', 'livrId': '40', 'capiNumero': '6', 'versNumero': '34'});
    });

    testWidgets('sem indicações mostra a mensagem', (tester) async {
      repository.recebidasLista = [];
      await montar(tester, criar(), []);
      expect(find.text('nenhumaIndicacaoRecebida'), findsOneWidget);
    });

    testWidgets('erro no primeiro carregamento: tentar novamente; erro na atualização: SnackBar', (tester) async {
      repository.erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar(), []);
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erro = null;
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('João 3:16'), findsOneWidget);

      repository.erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      await tester.tap(find.byTooltip('atualizar'));
      await tester.pumpAndSettle();
      expect(find.text('João 3:16'), findsOneWidget, reason: 'mantém a lista');
      expect(find.widgetWithText(SnackBar, 'erroGeralApi'), findsOneWidget);
    });
  });
}
