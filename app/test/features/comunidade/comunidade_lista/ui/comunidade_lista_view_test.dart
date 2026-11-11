import 'dart:async';

import 'package:app/config/icons_map.dart';
import 'package:app/data/model/comunidade/comunidade_local_model.dart';
import 'package:app/data/model/localidade/estado_model.dart';
import 'package:app/data/model/localidade/municipio_model.dart';
import 'package:app/features/comunidade/comunidade_lista/repository/comunidade_lista_repository.dart';
import 'package:app/features/comunidade/comunidade_lista/ui/comunidade_lista_view.dart';
import 'package:app/features/comunidade/comunidade_lista/ui/comunidade_lista_viewmodel.dart';
import 'package:app/features/comunidade/comunidade_lista/use_case/comunidade_lista_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _matriz = ComunidadeLocalModel(
  comuId: 1,
  comuNome: 'paróquia Matriz',
  ctipNome: 'Paróquia',
  ctipIcone: 'home-group',
  cdenNome: 'Católica',
  cendLogradouro: 'Quadra 10',
  cendNumero: '6',
  cendComplemento: 'Lote 2',
  cendBairro: 'Sobradinho',
  muniId: 5300108,
  muniNome: 'Brasília',
  estaId: 53,
  estaSigla: 'DF',
);
const _capela = ComunidadeLocalModel(
  comuId: 2,
  comuNome: 'Capela',
  muniId: 5300108,
  estaId: 53,
  ctipIcone: 'cathedral',
);
const _goiania = ComunidadeLocalModel(comuId: 3, comuNome: 'Igreja Goiânia', muniId: 5208707, estaId: 52);

/// Comunidades por estado em memória; [espera] segura a próxima busca até ser completada.
class _FakeComunidadeListaRepository implements ComunidadeListaRepository {
  final porEstado = <int, List<ComunidadeLocalModel>>{
    53: [_matriz, _capela],
    52: [_goiania],
  };
  final buscas = <(int, int?)>[];
  int chamadasEstados = 0;
  final chamadasMunicipios = <int>[];
  Exception? erroBusca;
  Completer<void>? espera;

  @override
  Future<Result<List<EstadoModel>>> estados() async {
    chamadasEstados++;
    return const Result.ok([
      EstadoModel(estaId: 53, estaNome: 'Distrito Federal', estaSigla: 'DF'),
      EstadoModel(estaId: 52, estaNome: 'Goiás', estaSigla: 'GO'),
    ]);
  }

  @override
  Future<Result<List<MunicipioModel>>> municipios(int estaId) async {
    chamadasMunicipios.add(estaId);
    return Result.ok([
      if (estaId == 53) const MunicipioModel(muniId: 5300108, muniNome: 'Brasília', estaId: 53),
      if (estaId == 52) const MunicipioModel(muniId: 5208707, muniNome: 'Goiânia', estaId: 52),
    ]);
  }

  @override
  Future<Result<List<ComunidadeLocalModel>>> comunidades({required int estaId, int? muniId}) async {
    buscas.add((estaId, muniId));
    final aguardar = espera;
    if (aguardar != null) {
      espera = null;
      await aguardar.future;
    }
    final erro = erroBusca;
    if (erro != null) return Result.error(erro);
    return Result.ok([
      for (final c in porEstado[estaId] ?? const <ComunidadeLocalModel>[])
        if (muniId == null || c.muniId == muniId) c,
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
  late _FakeComunidadeListaRepository repository;

  setUp(() => repository = _FakeComunidadeListaRepository());

  ComunidadeListaUseCase criarUseCase() => ComunidadeListaUseCase(comunidadeListaRepository: repository);

  ComunidadeListaViewmodel criar() => ComunidadeListaViewmodel(comunidadeListaUseCase: criarUseCase());

  Future<void> montar(WidgetTester tester, ComunidadeListaViewmodel viewModel) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: ComunidadeListaView(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> escolher(WidgetTester tester, String rotulo, String opcao) async {
    await tester.tap(find.byWidgetPredicate((w) => w is InputDecorator && w.decoration.labelText == rotulo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  group('ComunidadeLocalModel', () {
    test('fromJson aceita camelCase e snake_case; número inteiro vira texto', () {
      final camel = ComunidadeLocalModel.fromJson({
        'comuId': 1,
        'comuNome': 'Matriz',
        'ctipIcone': 'church',
        'cendNumero': 6,
        'muniId': '5300108',
        'estaId': 53,
      });
      expect((camel.comuId, camel.ctipIcone, camel.cendNumero, camel.muniId), (1, 'church', '6', 5300108));

      final snake = ComunidadeLocalModel.fromJson({
        'comu_id': 2,
        'comu_nome': 'Capela',
        'cden_nome': 'Católica',
        'muni_id': 1,
        'esta_id': 2,
        'esta_sigla': 'GO',
      });
      expect((snake.cdenNome, snake.estaSigla, snake.cendLogradouro), ('Católica', 'GO', null));
    });

    test('fromJson sem nome lança FormatException', () {
      expect(() => ComunidadeLocalModel.fromJson({'comuId': 1, 'muniId': 1, 'estaId': 1}), throwsFormatException);
    });
  });

  group('ComunidadeListaUseCase', () {
    test('sem estado não chama a API (selecioneEstado)', () async {
      final result = await criarUseCase().comunidades();
      expect(((result as Error).error as HandledException).message, 'selecioneEstado');
      expect(repository.buscas, isEmpty);
    });

    test('ordena por nome sem diferenciar maiúsculas; cidade de outro estado é ignorada', () async {
      final useCase = criarUseCase();
      final lista = (await useCase.comunidades(estaId: 53) as Ok<List<ComunidadeLocalModel>>).value;
      expect(lista.map((c) => c.comuNome), ['Capela', 'paróquia Matriz']);

      await useCase.comunidades(
        estaId: 53,
        muniId: 5208707,
        municipiosDoEstado: const [MunicipioModel(muniId: 5300108, muniNome: 'Brasília', estaId: 53)],
      );
      expect(repository.buscas.last, (53, null));
    });

    test('404 registroNaoEncontrado vira lista vazia; outro erro passa', () async {
      final useCase = criarUseCase();
      repository.erroBusca = HttpServiceException(message: 'registroNaoEncontrado');
      expect((await useCase.comunidades(estaId: 53) as Ok<List<ComunidadeLocalModel>>).value, isEmpty);
      repository.erroBusca = HttpServiceException(message: 'erroGeralApi', code: 500);
      expect(await useCase.comunidades(estaId: 53), isA<Error<List<ComunidadeLocalModel>>>());
    });

    test('estados e municípios ficam em cache', () async {
      final useCase = criarUseCase();
      await useCase.estados();
      await useCase.estados();
      await useCase.municipios(53);
      await useCase.municipios(53);
      expect(repository.chamadasEstados, 1);
      expect(repository.chamadasMunicipios, [53]);
    });

    test('textos do card', () {
      expect(ComunidadeListaUseCase.descricao(_matriz), 'Paróquia · Católica');
      expect(ComunidadeListaUseCase.linhaEndereco(_matriz), 'Quadra 10, 6 - Lote 2');
      expect(ComunidadeListaUseCase.linhaLocal(_matriz), 'Sobradinho · Brasília - DF');
      expect(ComunidadeListaUseCase.descricao(_capela), isNull);
      expect(ComunidadeListaUseCase.linhaEndereco(_capela), isNull);
      expect(ComunidadeListaUseCase.linhaLocal(_capela), isNull);
    });
  });

  group('ComunidadeListaViewmodel', () {
    test('carrega os estados ao criar; estado busca e carrega cidades; cidade filtra', () async {
      final viewModel = criar();
      await pumpEventQueue();
      expect(viewModel.estados, hasLength(2));
      expect(viewModel.comunidades, isNull);

      await viewModel.selecionarEstado(53);
      expect(viewModel.municipios?.single.muniNome, 'Brasília');
      expect(viewModel.comunidades, hasLength(2));

      await viewModel.selecionarCidade(5300108);
      expect(repository.buscas.last, (53, 5300108));

      await viewModel.selecionarEstado(52);
      expect(viewModel.muniId, isNull, reason: 'trocar o estado limpa a cidade');
      expect(viewModel.comunidades?.single.comuNome, 'Igreja Goiânia');
    });

    test('filtro trocado durante a busca: busca de novo e mostra só o atual', () async {
      final viewModel = criar();
      await pumpEventQueue();
      final espera = repository.espera = Completer<void>();
      final primeira = viewModel.selecionarEstado(53);
      await pumpEventQueue();
      final segunda = viewModel.selecionarEstado(52);
      espera.complete();
      await Future.wait([primeira, segunda]);
      await pumpEventQueue();

      expect(repository.buscas.last, (52, null));
      expect(viewModel.comunidades?.single.comuNome, 'Igreja Goiânia');
    });
  });

  group('ComunidadeListaView', () {
    testWidgets('sem estado pede para selecionar; ao escolher, lista com ícone do tipo e endereço', (tester) async {
      await montar(tester, criar());
      expect(find.text('encontrarComunidades'), findsOneWidget);
      expect(find.text('selecioneEstado'), findsOneWidget);
      expect(repository.buscas, isEmpty);

      await escolher(tester, 'estado', 'DF · Distrito Federal');

      expect(find.text('paróquia Matriz'), findsOneWidget);
      expect(find.text('Paróquia · Católica'), findsOneWidget);
      expect(find.text('Quadra 10, 6 - Lote 2'), findsOneWidget);
      expect(find.text('Sobradinho · Brasília - DF'), findsOneWidget);
      expect(find.text('Capela'), findsOneWidget);

      Icon iconeDoCard(String nome) => tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(of: find.text(nome), matching: find.byType(Card)),
          matching: find.descendant(of: find.byType(CircleAvatar), matching: find.byType(Icon)),
        ),
      );
      expect(iconeDoCard('paróquia Matriz').icon, IconsMap.mdiIcons['home-group']);
      expect(iconeDoCard('Capela').icon, IconsMap.mdiIcons['church'], reason: 'ícone fora do mapa usa o padrão');
    });

    testWidgets('cidade filtra; "todas as cidades" volta a listar o estado', (tester) async {
      await montar(tester, criar());
      await escolher(tester, 'estado', 'GO · Goiás');
      await escolher(tester, 'municipio', 'Goiânia');
      expect(repository.buscas.last, (52, 5208707));
      expect(find.text('Igreja Goiânia'), findsOneWidget);

      await escolher(tester, 'municipio', 'todasAsCidades');
      expect(repository.buscas.last, (52, null));
    });

    testWidgets('sem comunidades no local mostra a mensagem', (tester) async {
      repository.porEstado.remove(52);
      await montar(tester, criar());
      await escolher(tester, 'estado', 'GO · Goiás');
      expect(find.text('nenhumaComunidadeNoLocal'), findsOneWidget);
    });

    testWidgets('erro na primeira busca mostra tentar novamente', (tester) async {
      repository.erroBusca = HttpServiceException(message: 'erroGeralApi', code: 500);
      await montar(tester, criar());
      await escolher(tester, 'estado', 'DF · Distrito Federal');
      expect(find.text('erroGeralApi'), findsOneWidget);

      repository.erroBusca = null;
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Capela'), findsOneWidget);
    });

    testWidgets('erro numa atualização mantém a lista e mostra SnackBar', (tester) async {
      await montar(tester, criar());
      await escolher(tester, 'estado', 'DF · Distrito Federal');
      repository.erroBusca = HttpServiceException(message: 'erroGeralApi', code: 500);
      await tester.tap(find.byTooltip('atualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Capela'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'erroGeralApi'), findsOneWidget);
    });
  });
}
