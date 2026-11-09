import 'package:app/data/model/musica/musica_model.dart';
import 'package:app/features/dashboard/widgets/musica/repository/musica_repository.dart';
import 'package:app/features/dashboard/widgets/musica/ui/musica_view.dart';
import 'package:app/features/dashboard/widgets/musica/ui/musica_viewmodel.dart';
import 'package:app/features/dashboard/widgets/musica/use_case/musica_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

/// Devolve, em ordem, as respostas configuradas (como sorteios sucessivos de `GET /v1/musica/aleatoria`).
class _FakeMusicaRepository implements MusicaRepository {
  _FakeMusicaRepository(this.respostas);

  final List<Result<MusicaModel>> respostas;
  int chamadas = 0;

  @override
  Future<Result<MusicaModel>> aleatoria() async => respostas[chamadas++ % respostas.length];
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

const _noites = MusicaModel(
  musiId: 7,
  musiNome: 'Noites Traiçoeiras',
  musiArtista: 'Padre Marcelo Rossi',
  mgenNome: 'Música Católica',
  musiInspiracao: '  Inspirada no Salmo 23.  ',
  musiSpotify: 'https://open.spotify.com/search/noites',
  musiDeezer: 'https://www.deezer.com/search/noites',
  musiAppleMusic: 'https://music.apple.com/search?term=noites',
);

const _semLinks = MusicaModel(
  musiId: 8,
  musiNome: 'Sem Links',
  musiArtista: 'Artista',
  mgenNome: 'Gospel',
  musiSpotify: '',
  musiDeezer: 'nao-e-url',
  musiAppleMusic: 'ftp://music.apple.com/x',
);

void main() {
  late List<Uri> abertos;
  late bool abrirOk;

  setUp(() {
    abertos = [];
    abrirOk = true;
  });

  MusicaUseCase useCase(List<Result<MusicaModel>> respostas) => MusicaUseCase(
    musicaRepository: _FakeMusicaRepository(respostas),
    abrirUrl: (url) async {
      abertos.add(url);
      return abrirOk;
    },
  );

  MusicaViewmodel criar(List<Result<MusicaModel>> respostas) => MusicaViewmodel(musicaUseCase: useCase(respostas));

  Future<void> montar(WidgetTester tester, MusicaViewmodel viewModel) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Scaffold(
          body: SingleChildScrollView(child: MusicaView(viewModel: viewModel)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MusicaUseCase', () {
    test('repassa a música sorteada', () async {
      expect((await useCase([Result.ok(_noites)]).aleatoria() as Ok<MusicaModel>).value.musiId, 7);
    });

    test('404 registroNaoEncontrado vira nenhumaMusicaCadastrada', () async {
      final result = await useCase([Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404))])
          .aleatoria();
      expect(((result as Error).error as HandledException).message, 'nenhumaMusicaCadastrada');
    });

    test('outros erros são repassados sem alteração', () async {
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      expect((await useCase([Result.error(erro)]).aleatoria() as Error).error, same(erro));
    });

    test('links válidos na ordem das plataformas; inválidos são ignorados', () {
      final uc = useCase([Result.ok(_noites)]);
      expect(uc.links(_noites).map((l) => l.plataforma), MusicaPlataforma.values);
      expect(uc.links(_semLinks), isEmpty);
    });

    test('inspiração sem espaços e nula quando vazia', () {
      final uc = useCase([Result.ok(_noites)]);
      expect(uc.inspiracao(_noites), 'Inspirada no Salmo 23.');
      expect(uc.inspiracao(_semLinks), isNull);
    });

    test('falha ao abrir o link vira naoFoiPossivelAbrirLink', () async {
      abrirOk = false;
      final uc = useCase([Result.ok(_noites)]);
      final result = await uc.abrirLink(uc.links(_noites).first);
      expect(((result as Error).error as HandledException).message, 'naoFoiPossivelAbrirLink');
    });
  });

  group('MusicaModel', () {
    test('lê o JSON da API em camelCase, com campos opcionais nulos', () {
      final model = MusicaModel.fromJson({
        'musiId': 1,
        'musiNome': 'Nome',
        'musiArtista': 'Artista',
        'mgenNome': 'Rock',
        'musiInspiracao': null,
        'musiSpotify': null,
        'musiDeezer': null,
        'musiAppleMusic': null,
      });
      expect(model.musiId, 1);
      expect(model.mgenNome, 'Rock');
      expect(model.musiSpotify, isNull);
    });
  });

  group('MusicaViewmodel', () {
    test('carrega uma música ao ser criado e sorteia outra no comando', () async {
      final viewModel = criar([Result.ok(_noites), Result.ok(_semLinks)]);
      await pumpEventQueue();
      expect(viewModel.musica?.musiId, 7);
      expect(viewModel.links, hasLength(3));

      await viewModel.aleatoriaCommand.execute();
      expect(viewModel.musica?.musiId, 8);
      expect(viewModel.links, isEmpty);
      expect(viewModel.inspiracao, isNull);
    });

    test('erro em novo sorteio mantém a música atual', () async {
      final viewModel = criar([Result.ok(_noites), Result.error(HandledException(message: 'erroApi'))]);
      await pumpEventQueue();
      await viewModel.aleatoriaCommand.execute();
      expect(viewModel.aleatoriaCommand.error, isTrue);
      expect(viewModel.musica?.musiId, 7);
    });
  });

  group('MusicaView', () {
    testWidgets('mostra a música, abre o link e sorteia outra', (tester) async {
      await montar(tester, criar([Result.ok(_noites), Result.ok(_semLinks)]));

      expect(find.text('Noites Traiçoeiras'), findsOneWidget);
      expect(find.text('Padre Marcelo Rossi · Música Católica'), findsOneWidget);
      expect(find.text('Inspirada no Salmo 23.'), findsOneWidget);
      expect(find.text('ouvirEm'), findsOneWidget);

      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();
      expect(abertos.single.host, 'open.spotify.com');

      await tester.tap(find.text('outraMusica'));
      await tester.pumpAndSettle();
      expect(find.text('Sem Links'), findsOneWidget);
      expect(find.text('ouvirEm'), findsNothing);
    });

    testWidgets('falha ao abrir o link avisa no SnackBar', (tester) async {
      abrirOk = false;
      await montar(tester, criar([Result.ok(_noites)]));

      await tester.tap(find.text('Deezer'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBar, 'naoFoiPossivelAbrirLink'), findsOneWidget);
    });

    testWidgets('sem músicas cadastradas mostra a mensagem e tenta novamente', (tester) async {
      await montar(
        tester,
        criar([Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)), Result.ok(_noites)]),
      );

      expect(find.text('nenhumaMusicaCadastrada'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Noites Traiçoeiras'), findsOneWidget);
    });

    testWidgets('erro em novo sorteio mantém a música e avisa no SnackBar', (tester) async {
      await montar(tester, criar([Result.ok(_noites), Result.error(HandledException(message: 'erroApi'))]));

      await tester.tap(find.text('outraMusica'));
      await tester.pumpAndSettle();
      expect(find.text('Noites Traiçoeiras'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'erroApi'), findsOneWidget);
    });
  });
}
