import 'package:app/data/model/comunidade/comunidade_denominacao_model.dart';
import 'package:app/data/model/comunidade/comunidade_model.dart';
import 'package:app/data/model/comunidade/comunidade_tipo_model.dart';
import 'package:app/data/model/comunidade/comunidade_usuario_model.dart';
import 'package:app/data/model/usuario/usuario_resumo_model.dart';
import 'package:app/features/comunidade/comunidade/repository/comunidade_repository.dart';
import 'package:app/features/comunidade/comunidade/use_case/comunidade_usecase.dart';
import 'package:app/features/comunidade/comunidade_usuario/repository/comunidade_usuario_repository.dart';
import 'package:app/features/comunidade/comunidade_usuario/ui/comunidade_usuario_view.dart';
import 'package:app/features/comunidade/comunidade_usuario/ui/comunidade_usuario_viewmodel.dart';
import 'package:app/features/comunidade/comunidade_usuario/ui/widgets/comunidade_usuario_adicionar_dialog.dart';
import 'package:app/features/comunidade/comunidade_usuario/use_case/comunidade_usuario_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service/service.dart';

const _matriz = ComunidadeModel(comuId: 1, comuNome: 'Paróquia Matriz', ctipId: 1, cdenId: 1);
const _capela = ComunidadeModel(comuId: 2, comuNome: 'Capela São José');

const _ana = ComunidadeUsuarioModel(cusuId: 10, comuId: 1, usuaId: 3, udetNome: 'Ana Souza', udetUsuario: 'ana');
const _bruno = ComunidadeUsuarioModel(
  cusuId: 11,
  comuId: 1,
  usuaId: 4,
  cusuAtivo: false,
  udetNome: 'Bruno Lima',
  udetUsuario: 'bruno',
);
const _carla = UsuarioResumoModel(usuaId: 5, udetNome: 'Carla Dias', udetUsuario: 'carla');

/// Só a listagem de comunidades é usada por esta aba.
class _FakeComunidadeRepository implements ComunidadeRepository {
  _FakeComunidadeRepository(this.comunidades);

  final List<ComunidadeModel> comunidades;

  @override
  Future<Result<List<ComunidadeModel>>> comunidadesDoUsuario(int usuaId) async => Result.ok(comunidades);

  @override
  Future<Result<List<ComunidadeTipoModel>>> tipos() async => const Result.ok([]);

  @override
  Future<Result<List<ComunidadeDenominacaoModel>>> denominacoes() async => const Result.ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Vínculos por comunidade em memória; a busca devolve [encontraveis] filtrados pelo texto.
class _FakeComunidadeUsuarioRepository implements ComunidadeUsuarioRepository {
  _FakeComunidadeUsuarioRepository(Map<int, List<ComunidadeUsuarioModel>> porComunidade)
    : porComunidade = {
        for (final e in porComunidade.entries) e.key: [...e.value],
      };

  final Map<int, List<ComunidadeUsuarioModel>> porComunidade;
  final encontraveis = <UsuarioResumoModel>[
    const UsuarioResumoModel(usuaId: 3, udetNome: 'Ana Souza', udetUsuario: 'ana'),
    _carla,
  ];
  final erros = <int, Exception>{};
  final consultas = <int>[];
  final buscas = <String>[];
  final incluidos = <ComunidadeUsuarioModel>[];
  final alterados = <ComunidadeUsuarioModel>[];
  final excluidos = <int>[];
  int _proximoId = 50;

  @override
  Future<Result<List<ComunidadeUsuarioModel>>> usuarios(int comuId) async {
    consultas.add(comuId);
    final erro = erros[comuId];
    return erro != null ? Result.error(erro) : Result.ok(List.of(porComunidade[comuId] ?? const []));
  }

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) async {
    buscas.add(texto);
    final t = texto.toLowerCase();
    return Result.ok(encontraveis.where((u) => '${u.udetNome} ${u.udetUsuario}'.toLowerCase().contains(t)).toList());
  }

  @override
  Future<Result<ComunidadeUsuarioModel>> incluir(ComunidadeUsuarioModel vinculo) async {
    incluidos.add(vinculo);
    final usuario = encontraveis.firstWhere((u) => u.usuaId == vinculo.usuaId);
    final gravado = ComunidadeUsuarioModel(
      cusuId: _proximoId++,
      comuId: vinculo.comuId,
      usuaId: vinculo.usuaId,
      cusuAtivo: vinculo.cusuAtivo,
      udetNome: usuario.udetNome,
      udetUsuario: usuario.udetUsuario,
    );
    (porComunidade[vinculo.comuId] ??= []).add(gravado);
    return Result.ok(ComunidadeUsuarioModel(cusuId: gravado.cusuId, comuId: vinculo.comuId, usuaId: vinculo.usuaId));
  }

  @override
  Future<Result<ComunidadeUsuarioModel>> alterar(ComunidadeUsuarioModel vinculo) async {
    alterados.add(vinculo);
    final lista = porComunidade[vinculo.comuId]!;
    lista[lista.indexWhere((u) => u.cusuId == vinculo.cusuId)] = vinculo;
    return Result.ok(vinculo);
  }

  @override
  Future<Result<void>> excluir(int cusuId) async {
    excluidos.add(cusuId);
    for (final lista in porComunidade.values) {
      lista.removeWhere((u) => u.cusuId == cusuId);
    }
    return const Result.ok(null);
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
  late _FakeComunidadeUsuarioRepository repository;

  setUp(
    () => repository = _FakeComunidadeUsuarioRepository({
      1: [_bruno, _ana],
    }),
  );

  ComunidadeUsuarioUseCase criarUseCase([List<ComunidadeModel> comunidades = const [_matriz, _capela]]) =>
      ComunidadeUsuarioUseCase(
        comunidadeUsuarioRepository: repository,
        comunidadeUseCase: ComunidadeUseCase(
          comunidadeRepository: _FakeComunidadeRepository(comunidades),
          usuarioLogado: () => 7,
        ),
      );

  ComunidadeUsuarioViewmodel criar([List<ComunidadeModel> comunidades = const [_matriz, _capela]]) =>
      ComunidadeUsuarioViewmodel(comunidadeUsuarioUseCase: criarUseCase(comunidades));

  /// Monta a aba sozinha (como na tela de comunidades: seleciona [comuId] e abre). O botão "adicionarUsuario" faz
  /// o papel do botão inferior da tela; [onRemover] recebe o pedido de remoção (a confirmação é da tela).
  Future<void> montar(
    WidgetTester tester,
    ComunidadeUsuarioViewmodel viewModel, {
    int? comuId,
    ValueChanged<ComunidadeUsuarioModel>? onRemover,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (comuId != null) viewModel.selecionar(comuId);
    viewModel.abrir();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: Builder(
          builder: (context) => Scaffold(
            body: ComunidadeUsuarioView(viewModel: viewModel, onRemover: onRemover ?? (_) {}),
            bottomNavigationBar: TextButton(
              onPressed: () => ComunidadeUsuarioAdicionarDialog.show(
                context,
                viewModel: viewModel,
                comunidadeNome: viewModel.selecionada!.comunidade.comuNome,
              ),
              child: const Text('adicionarUsuario'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ComunidadeUsuarioModel', () {
    test('fromJson aceita camelCase e snake_case; cusuAtivo padrão true; toJson sem o nome', () {
      final camel = ComunidadeUsuarioModel.fromJson({
        'cusuId': 1,
        'comuId': '2',
        'usuaId': 3,
        'cusuAtivo': false,
        'udetNome': 'Ana',
      });
      expect((camel.cusuId, camel.comuId, camel.usuaId, camel.cusuAtivo, camel.udetNome), (1, 2, 3, false, 'Ana'));

      final snake = ComunidadeUsuarioModel.fromJson({'cusu_id': 4, 'comu_id': 5, 'usua_id': 6, 'udet_usuario': 'x'});
      expect((snake.cusuAtivo, snake.udetUsuario), (true, 'x'));
      expect(snake.toJson().keys, ['cusuId', 'comuId', 'usuaId', 'cusuAtivo']);
    });

    test('fromJson com cusuAtivo fora do formato lança FormatException', () {
      expect(
        () => ComunidadeUsuarioModel.fromJson({'comuId': 1, 'usuaId': 1, 'cusuAtivo': 'sim'}),
        throwsFormatException,
      );
    });
  });

  group('ComunidadeUsuarioUseCase', () {
    test('usuarios: ativos primeiro, depois por nome; 404 vira lista vazia', () async {
      repository.porComunidade[1] = [
        _bruno,
        const ComunidadeUsuarioModel(cusuId: 12, comuId: 1, usuaId: 8, udetNome: 'zeca'),
        _ana,
      ];
      final useCase = criarUseCase();
      final lista = (await useCase.usuarios(1) as Ok<List<ComunidadeUsuarioModel>>).value;
      expect(lista.map((u) => u.udetNome), ['Ana Souza', 'zeca', 'Bruno Lima']);

      repository.erros[2] = HttpServiceException(message: 'registroNaoEncontrado');
      expect((await useCase.usuarios(2) as Ok<List<ComunidadeUsuarioModel>>).value, isEmpty);
    });

    test('buscar exige 2 caracteres e não lista quem já está na comunidade', () async {
      final useCase = criarUseCase();
      expect((await useCase.buscar(' a ', [_ana]) as Ok).value, isEmpty);
      expect(repository.buscas, isEmpty, reason: 'menos de 2 caracteres não chama a API');

      final encontrados = (await useCase.buscar('a', [_ana, _bruno]) as Ok).value;
      expect(encontrados, isEmpty);
      final porNome = (await useCase.buscar('Souza', const []) as Ok<List<UsuarioResumoModel>>).value;
      expect(porNome.single.usuaId, 3);
      final semMembro = (await useCase.buscar('ar', [_ana]) as Ok<List<UsuarioResumoModel>>).value;
      expect(semMembro.map((u) => u.usuaId), [5]);
    });

    test('adicionar vincula ativo, com o nome; recusa membro repetido e sem comunidade', () async {
      final useCase = criarUseCase();
      final result = await useCase.adicionar(1, _carla, [_ana]);
      final gravado = (result as Ok<ComunidadeUsuarioModel>).value;
      expect((gravado.usuaId, gravado.cusuAtivo, gravado.udetNome), (5, true, 'Carla Dias'));
      expect(repository.incluidos.single.comuId, 1);

      final repetido = await useCase.adicionar(1, const UsuarioResumoModel(usuaId: 3), [_ana]);
      expect(((repetido as Error).error as HandledException).message, 'usuarioJaNaComunidade');
      final semComunidade = await useCase.adicionar(null, _carla, const []);
      expect(((semComunidade as Error).error as HandledException).message, 'comunidadeObrigatoria');
      expect(repository.incluidos, hasLength(1));
    });

    test('alternarAtivo inverte o vínculo; remover exclui pelo cusuId', () async {
      final useCase = criarUseCase();
      await useCase.alternarAtivo(_bruno);
      expect(repository.alterados.single.cusuAtivo, isTrue);

      await useCase.remover(_ana);
      expect(repository.excluidos, [10]);
    });

    test('nome e iniciais', () {
      expect(ComunidadeUsuarioUseCase.nomeExibicao(udetNome: ' ', udetUsuario: 'ana'), 'ana');
      expect(ComunidadeUsuarioUseCase.nomeExibicao(), isNull);
      expect(ComunidadeUsuarioUseCase.iniciais(udetNome: 'ana maria souza'), 'AS');
      expect(ComunidadeUsuarioUseCase.iniciais(udetUsuario: 'bruno'), 'B');
      expect(ComunidadeUsuarioUseCase.iniciais(), '?');
    });
  });

  group('ComunidadeUsuarioViewmodel', () {
    test('só carrega ao abrir; selecionar antes de carregar vale no carregamento', () async {
      final viewModel = criar();
      expect(repository.consultas, isEmpty);

      viewModel.selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();
      expect(viewModel.selecionada?.comunidade.comuId, 1);
      expect(viewModel.usuarios.map((u) => u.usuaId), [3, 4]);

      viewModel.invalidar();
      viewModel.abrir();
      await pumpEventQueue();
      expect(repository.consultas, [1, 1]);
    });

    test('buscar e adicionar: quem entra sai do resultado e aparece na lista', () async {
      final viewModel = criar()..selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();

      await viewModel.buscar('ar');
      expect(viewModel.encontrados.map((u) => u.usuaId), [5]);
      expect(viewModel.buscou, isTrue);

      await viewModel.adicionarCommand.execute(_carla);
      expect(viewModel.encontrados, isEmpty);
      expect(viewModel.usuarios.map((u) => u.usuaId), containsAll([3, 4, 5]));

      viewModel.limparBusca();
      expect(viewModel.buscou, isFalse);
      expect(viewModel.encontrados, isEmpty);
    });

    test('ativar e remover recarregam os usuários', () async {
      final viewModel = criar()..selecionar(1);
      viewModel.abrir();
      await pumpEventQueue();

      await viewModel.ativarCommand.execute(_bruno);
      expect(viewModel.usuarios.every((u) => u.cusuAtivo), isTrue);

      await viewModel.removerCommand.execute(_ana);
      expect(viewModel.usuarios.map((u) => u.usuaId), [4]);
    });
  });

  group('ComunidadeUsuarioView', () {
    testWidgets('abre na comunidade do comuId; lista nome, @usuario, iniciais e marca o inativo', (tester) async {
      await montar(tester, criar(), comuId: 1);

      expect(find.text('Paróquia Matriz'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('@ana'), findsOneWidget);
      expect(find.text('AS'), findsOneWidget);
      expect(find.text('Bruno Lima'), findsOneWidget);
      expect(find.text('inativo'), findsOneWidget, reason: 'só o Bruno está inativo');
    });

    testWidgets('sem comuId abre na primeira comunidade por nome', (tester) async {
      await montar(tester, criar());
      expect(repository.consultas, [2], reason: 'Capela vem antes de Paróquia');
      expect(find.text('Capela São José'), findsOneWidget);
    });

    testWidgets('menu: desativar/ativar e remover', (tester) async {
      final removidos = <ComunidadeUsuarioModel>[];
      await montar(tester, criar(), comuId: 1, onRemover: removidos.add);

      await tester.tap(find.byTooltip('acoes').first); // Ana (ativa) vem primeiro
      await tester.pumpAndSettle();
      expect(find.text('desativar'), findsOneWidget);
      await tester.tap(find.text('desativar'));
      await tester.pumpAndSettle();
      expect(repository.alterados.single.cusuAtivo, isFalse);
      expect(find.text('inativo'), findsNWidgets(2));

      await tester.tap(find.byTooltip('acoes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('remover'));
      await tester.pumpAndSettle();
      expect(removidos.single.usuaId, 3, reason: 'a confirmação fica com a tela');
      expect(repository.excluidos, isEmpty);
    });

    testWidgets('sem usuários e sem comunidades mostram a mensagem', (tester) async {
      await montar(tester, criar());
      expect(find.text('nenhumUsuarioNaComunidade'), findsOneWidget);

      await montar(tester, criar(const []));
      expect(find.text('nenhumaComunidadeCadastrada'), findsOneWidget);
    });

    testWidgets('"Adicionar usuário" abre a busca com espera e adiciona', (tester) async {
      final viewModel = criar();
      await montar(tester, viewModel, comuId: 1);
      await tester.tap(find.text('adicionarUsuario'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(ComunidadeUsuarioAdicionarDialog.esperaBusca);
      await tester.pumpAndSettle();
      expect(find.text('nenhumUsuarioEncontrado'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'car');
      await tester.pump(const Duration(milliseconds: 100));
      expect(repository.buscas, ['zzz'], reason: 'espera antes de buscar');
      await tester.pump(ComunidadeUsuarioAdicionarDialog.esperaBusca);
      await tester.pumpAndSettle();
      expect(find.text('Carla Dias'), findsOneWidget);

      await tester.tap(find.byTooltip('adicionarUsuario').last);
      await tester.pumpAndSettle();
      expect(repository.incluidos.single.usuaId, 5);
      expect(find.text('Carla Dias'), findsOneWidget, reason: 'agora na lista da aba, não na busca');

      await tester.tap(find.text('fechar'));
      await tester.pumpAndSettle();
      expect(viewModel.encontrados, isEmpty);
    });
  });
}
