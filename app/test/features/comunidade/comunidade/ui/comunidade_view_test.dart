import 'package:app/config/icons_map.dart';
import 'package:app/data/model/comunidade/comunidade_contato_model.dart';
import 'package:app/data/model/comunidade/comunidade_denominacao_model.dart';
import 'package:app/data/model/comunidade/comunidade_model.dart';
import 'package:app/data/model/comunidade/comunidade_tipo_model.dart';
import 'package:app/data/model/localidade/estado_model.dart';
import 'package:app/data/model/localidade/municipio_model.dart';
import 'package:app/data/model/comunidade/comunidade_endereco_model.dart';
import 'package:app/features/comunidade/comunidade_contato/repository/comunidade_contato_repository.dart';
import 'package:app/features/comunidade/comunidade_contato/ui/comunidade_contato_viewmodel.dart';
import 'package:app/features/comunidade/comunidade_contato/use_case/comunidade_contato_usecase.dart';
import 'package:app/features/comunidade/comunidade_endereco/repository/comunidade_endereco_repository.dart';
import 'package:app/features/comunidade/comunidade_endereco/ui/comunidade_endereco_viewmodel.dart';
import 'package:app/features/comunidade/comunidade_endereco/use_case/comunidade_endereco_usecase.dart';
import 'package:app/features/comunidade/comunidade/repository/comunidade_repository.dart';
import 'package:app/features/comunidade/comunidade/ui/comunidade_view.dart';
import 'package:app/features/comunidade/comunidade/ui/comunidade_viewmodel.dart';
import 'package:app/features/comunidade/comunidade/use_case/comunidade_usecase.dart';
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

/// Banco em memória: a lista começa com [comunidades]; incluir, alterar e excluir mexem nela como a API.
/// [respostasLista], se preenchida, substitui em ordem as respostas da listagem.
class _FakeComunidadeRepository implements ComunidadeRepository {
  _FakeComunidadeRepository([List<ComunidadeModel> comunidades = const []]) : comunidades = [...comunidades];

  final List<ComunidadeModel> comunidades;
  final respostasLista = <Result<List<ComunidadeModel>>>[];
  final usuarios = <int>[];
  final gravados = <(String, ComunidadeModel)>[];
  final excluidos = <int>[];
  Exception? erroTipos;
  Exception? erroDenominacoes;
  Exception? erroGravar;
  int _proximoId = 100;

  @override
  Future<Result<List<ComunidadeModel>>> comunidadesDoUsuario(int usuaId) async {
    usuarios.add(usuaId);
    if (respostasLista.isNotEmpty) return respostasLista.removeAt(0);
    return Result.ok(List.of(comunidades));
  }

  @override
  Future<Result<List<ComunidadeTipoModel>>> tipos() async => erroTipos != null
      ? Result.error(erroTipos!)
      : const Result.ok([
          ComunidadeTipoModel(ctipId: 1, ctipNome: 'Paróquia', ctipIcone: 'home-group'),
          ComunidadeTipoModel(ctipId: 2, ctipNome: 'Capela', ctipIcone: 'cathedral'),
        ]);

  @override
  Future<Result<List<ComunidadeDenominacaoModel>>> denominacoes() async => erroDenominacoes != null
      ? Result.error(erroDenominacoes!)
      : const Result.ok([ComunidadeDenominacaoModel(cdenId: 2, cdenNome: 'Católica')]);

  @override
  Future<Result<ComunidadeModel>> incluir(ComunidadeModel comunidade) async {
    gravados.add(('incluir', comunidade));
    if (erroGravar != null) return Result.error(erroGravar!);
    final gravada = ComunidadeModel(
      comuId: _proximoId++,
      comuNome: comunidade.comuNome,
      ctipId: comunidade.ctipId,
      cdenId: comunidade.cdenId,
      usuaId: _usuario,
    );
    comunidades.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<ComunidadeModel>> alterar(ComunidadeModel comunidade) async {
    gravados.add(('alterar', comunidade));
    if (erroGravar != null) return Result.error(erroGravar!);
    final indice = comunidades.indexWhere((c) => c.comuId == comunidade.comuId);
    comunidades[indice] = comunidade;
    return Result.ok(comunidade);
  }

  @override
  Future<Result<void>> excluir(int comuId) async {
    excluidos.add(comuId);
    comunidades.removeWhere((c) => c.comuId == comuId);
    return const Result.ok(null);
  }
}

/// Endereços em memória: só "Paróquia Matriz" (comuId 1) começa com um; incluir e excluir mexem na lista.
class _FakeComunidadeEnderecoRepository implements ComunidadeEnderecoRepository {
  final consultas = <int>[];
  final gravados = <ComunidadeEnderecoModel>[];
  final excluidos = <int>[];
  final porComunidade = <int, List<ComunidadeEnderecoModel>>{
    1: [
      const ComunidadeEnderecoModel(
        cendId: 1,
        comuId: 1,
        cendCep: '01001000',
        cendLogradouro: 'Praça da Sé',
        cendNumero: '1',
        muniId: 3550308,
        muniNome: 'São Paulo',
        estaId: 35,
        estaSigla: 'SP',
      ),
    ],
  };

  @override
  Future<Result<List<ComunidadeEnderecoModel>>> enderecos(int comuId) async {
    consultas.add(comuId);
    return Result.ok(List.of(porComunidade[comuId] ?? const []));
  }

  @override
  Future<Result<List<EstadoModel>>> estados() async =>
      const Result.ok([EstadoModel(estaId: 35, estaNome: 'São Paulo', estaSigla: 'SP')]);

  @override
  Future<Result<List<MunicipioModel>>> municipios(int estaId) async =>
      const Result.ok([MunicipioModel(muniId: 3550308, muniNome: 'São Paulo', estaId: 35)]);

  @override
  Future<Result<ComunidadeEnderecoModel>> incluir(ComunidadeEnderecoModel endereco) async {
    gravados.add(endereco);
    final gravado = ComunidadeEnderecoModel(
      cendId: 50,
      comuId: endereco.comuId,
      cendCep: endereco.cendCep,
      cendLogradouro: endereco.cendLogradouro,
      muniId: endereco.muniId,
    );
    (porComunidade[endereco.comuId] ??= []).add(gravado);
    return Result.ok(gravado);
  }

  @override
  Future<Result<ComunidadeEnderecoModel>> alterar(ComunidadeEnderecoModel endereco) async {
    gravados.add(endereco);
    return Result.ok(endereco);
  }

  @override
  Future<Result<void>> excluir(int cendId) async {
    excluidos.add(cendId);
    for (final lista in porComunidade.values) {
      lista.removeWhere((e) => e.cendId == cendId);
    }
    return const Result.ok(null);
  }
}

/// Contatos por comunidade em memória (comunidade 1 já tem um).
class _FakeComunidadeContatoRepository implements ComunidadeContatoRepository {
  final consultas = <int>[];
  final gravados = <ComunidadeContatoModel>[];
  final excluidos = <int>[];
  final porComunidade = <int, List<ComunidadeContatoModel>>{
    1: [const ComunidadeContatoModel(cconId: 1, comuId: 1, cconEmail: 'secretaria@matriz.org')],
  };

  @override
  Future<Result<List<ComunidadeContatoModel>>> contatos(int comuId) async {
    consultas.add(comuId);
    return Result.ok(List.of(porComunidade[comuId] ?? const []));
  }

  @override
  Future<Result<ComunidadeContatoModel>> incluir(ComunidadeContatoModel contato) async {
    gravados.add(contato);
    final gravado = ComunidadeContatoModel.comCampos(
      cconId: 60,
      comuId: contato.comuId,
      campos: {for (final chave in ComunidadeContatoModel.chaves) chave: contato.campo(chave)},
    );
    (porComunidade[contato.comuId] ??= []).add(gravado);
    return Result.ok(gravado);
  }

  @override
  Future<Result<ComunidadeContatoModel>> alterar(ComunidadeContatoModel contato) async {
    gravados.add(contato);
    return Result.ok(contato);
  }

  @override
  Future<Result<void>> excluir(int cconId) async {
    excluidos.add(cconId);
    for (final lista in porComunidade.values) {
      lista.removeWhere((c) => c.cconId == cconId);
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
  ComunidadeUseCase criarUseCase(_FakeComunidadeRepository repository, {int? usuario = _usuario}) =>
      ComunidadeUseCase(comunidadeRepository: repository, usuarioLogado: () => usuario);

  ComunidadeViewmodel criar(_FakeComunidadeRepository repository) =>
      ComunidadeViewmodel(comunidadeUseCase: criarUseCase(repository));

  Future<void> montar(
    WidgetTester tester,
    ComunidadeViewmodel viewModel, {
    _FakeComunidadeEnderecoRepository? enderecos,
    _FakeComunidadeContatoRepository? contatos,
  }) async {
    final contatoViewModel = ComunidadeContatoViewmodel(
      comunidadeContatoUseCase: ComunidadeContatoUseCase(
        comunidadeContatoRepository: contatos ?? _FakeComunidadeContatoRepository(),
        comunidadeUseCase: viewModel.comunidadeUseCase,
        abrirUrl: (_) async => true,
      ),
    );
    final enderecoViewModel = ComunidadeEnderecoViewmodel(
      comunidadeEnderecoUseCase: ComunidadeEnderecoUseCase(
        comunidadeEnderecoRepository: enderecos ?? _FakeComunidadeEnderecoRepository(),
        comunidadeUseCase: viewModel.comunidadeUseCase,
      ),
    );
    // tela de celular: o aviso de erro/confirmação (DialogBottomSheetWarning) tem largura de botões de celular
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        home: ComunidadeView(
          viewModel: viewModel,
          enderecoViewModel: enderecoViewModel,
          contatoViewModel: contatoViewModel,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Abre a aba [rotulo]; a TabBar rola, então a aba pode estar fora da tela (celular).
  Future<void> abrirAba(WidgetTester tester, String rotulo) async {
    final aba = find.widgetWithText(Tab, rotulo);
    await tester.ensureVisible(aba);
    await tester.pumpAndSettle();
    await tester.tap(aba);
    await tester.pumpAndSettle();
  }

  Future<void> escolher(WidgetTester tester, String rotulo, String opcao) async {
    await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, rotulo));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao).last);
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
      expect(criarUseCase(_FakeComunidadeRepository()).abas.first, ComunidadeAba.minhas);
    });

    test('lista as comunidades do usuário logado por nome, com tipo, denominação e opções', () async {
      final repository = _FakeComunidadeRepository([_matriz, _grupo, _capela]);
      final minhas = (await criarUseCase(repository).minhasComunidades() as Ok<MinhasComunidades>).value;
      final lista = minhas.comunidades;

      expect(repository.usuarios, [_usuario]);
      expect(lista.map((c) => c.comunidade.comuId), [2, 3, 1], reason: 'sem diferenciar maiúsculas');
      expect(ComunidadeUseCase.descricao(lista[2]), 'Paróquia · Católica');
      expect(ComunidadeUseCase.descricao(lista[0]), isNull, reason: 'tipo 9 não existe');
      expect(minhas.tipos, hasLength(2));
      expect(minhas.denominacoes, hasLength(1));
      expect(lista[2].icone, 'home-group', reason: 'ícone do tipo (ctip_icone)');
      expect(lista[0].icone, isNull, reason: 'sem tipo, sem ícone');
    });

    test('ComunidadeTipoModel lê o ícone (camelCase ou snake_case; opcional)', () {
      expect(
        ComunidadeTipoModel.fromJson({'ctipId': 4, 'ctipNome': 'Igreja', 'ctipIcone': 'church'}).ctipIcone,
        'church',
      );
      expect(
        ComunidadeTipoModel.fromJson({'ctip_id': 4, 'ctip_nome': 'Igreja', 'ctip_icone': 'cross'}).ctipIcone,
        'cross',
      );
      expect(ComunidadeTipoModel.fromJson({'ctipId': 1, 'ctipNome': 'X', 'ctipIcone': null}).ctipIcone, isNull);
    });

    test('falha em tipos ou denominações não impede a lista', () async {
      final repository = _FakeComunidadeRepository([_matriz])
        ..erroTipos = HttpServiceException(message: 'erroGeralApi', code: 500);
      final minhas = (await criarUseCase(repository).minhasComunidades() as Ok<MinhasComunidades>).value;

      expect(ComunidadeUseCase.descricao(minhas.comunidades.single), 'Católica');
      expect(minhas.tipos, isEmpty);
    });

    test('404 registroNaoEncontrado vira lista vazia e outros erros são repassados', () async {
      final erro = HttpServiceException(message: 'erroGeralApi', code: 500);
      final repository = _FakeComunidadeRepository()
        ..respostasLista.addAll([
          Result.error(HttpServiceException(message: 'registroNaoEncontrado', code: 404)),
          Result.error(erro),
        ]);
      final useCase = criarUseCase(repository);

      final vazia = (await useCase.minhasComunidades() as Ok<MinhasComunidades>).value;
      expect(vazia.comunidades, isEmpty);
      expect(vazia.tipos, isNotEmpty, reason: 'o formulário continua com opções');
      expect((await useCase.minhasComunidades() as Error).error, same(erro));
    });

    test('sem usuário logado devolve headerInvalido sem chamar a API', () async {
      final repository = _FakeComunidadeRepository();
      final useCase = criarUseCase(repository, usuario: null);

      expect(((await useCase.minhasComunidades() as Error).error as HandledException).message, 'headerInvalido');
      expect(((await useCase.salvar(_matriz) as Error).error as HandledException).message, 'headerInvalido');
      expect(repository.usuarios, isEmpty);
      expect(repository.gravados, isEmpty);
    });

    test('validar exige nome (até o máximo), tipo e denominação', () {
      final useCase = criarUseCase(_FakeComunidadeRepository());
      const valida = ComunidadeModel(comuNome: 'Nova', ctipId: 1, cdenId: 2);

      expect(useCase.validar(valida), isNull);
      expect(useCase.validar(const ComunidadeModel(comuNome: '   ', ctipId: 1, cdenId: 2)), 'nomeObrigatorio');
      expect(
        useCase.validar(ComunidadeModel(comuNome: 'x' * (ComunidadeUseCase.kNomeMax + 1), ctipId: 1, cdenId: 2)),
        'nomeComunidadeMuitoLongo',
      );
      expect(useCase.validar(const ComunidadeModel(comuNome: 'Nova', cdenId: 2)), 'tipoObrigatorio');
      expect(useCase.validar(const ComunidadeModel(comuNome: 'Nova', ctipId: 1)), 'denominacaoObrigatoria');
    });

    test('salvar inclui sem comuId e altera com comuId, com o nome sem espaços nas pontas', () async {
      final repository = _FakeComunidadeRepository([_matriz]);
      final useCase = criarUseCase(repository);

      await useCase.salvar(const ComunidadeModel(comuNome: '  Nova  ', ctipId: 1, cdenId: 2));
      await useCase.salvar(const ComunidadeModel(comuId: 1, comuNome: 'Matriz', ctipId: 2, cdenId: 2));

      expect(repository.gravados.map((g) => (g.$1, g.$2.comuId, g.$2.comuNome)), [
        ('incluir', null, 'Nova'),
        ('alterar', 1, 'Matriz'),
      ]);
    });

    test('salvar inválido não chama a API', () async {
      final repository = _FakeComunidadeRepository();
      final result = await criarUseCase(repository).salvar(const ComunidadeModel(comuNome: 'Nova', ctipId: 1));

      expect(((result as Error).error as HandledException).message, 'denominacaoObrigatoria');
      expect(repository.gravados, isEmpty);
    });

    test('excluir pelo comuId', () async {
      final repository = _FakeComunidadeRepository([_matriz]);
      await criarUseCase(repository).excluir(_matriz);
      expect(repository.excluidos, [1]);
    });
  });

  group('ComunidadeViewmodel', () {
    test('carrega a lista e as opções ao ser criado', () async {
      final viewModel = criar(_FakeComunidadeRepository([_matriz]));
      await pumpEventQueue();

      expect(viewModel.minhasCommand.completed, isTrue);
      expect(viewModel.minhas?.single.comunidade.comuNome, 'Paróquia Matriz');
      expect(viewModel.tipos, hasLength(2));
    });

    test('erro na atualização mantém a última lista', () async {
      final repository = _FakeComunidadeRepository([_matriz]);
      final viewModel = criar(repository);
      await pumpEventQueue();
      repository.respostasLista.add(Result.error(HttpServiceException(message: 'erroGeralApi', code: 500)));
      await viewModel.minhasCommand.execute();

      expect(viewModel.minhasCommand.error, isTrue);
      expect(viewModel.minhas, hasLength(1));
    });

    test('salvar e excluir recarregam a lista', () async {
      final repository = _FakeComunidadeRepository([_matriz]);
      final viewModel = criar(repository);
      await pumpEventQueue();

      await viewModel.salvarCommand.execute(const ComunidadeModel(comuNome: 'Nova', ctipId: 2, cdenId: 2));
      expect(viewModel.minhas?.map((c) => c.comunidade.comuNome), ['Nova', 'Paróquia Matriz']);

      await viewModel.excluirCommand.execute(_matriz);
      expect(viewModel.minhas?.map((c) => c.comunidade.comuNome), ['Nova']);
    });
  });

  group('ComunidadeView', () {
    testWidgets('o card usa o ícone do tipo da API; sem ícone ou ícone não mapeado, o padrão', (tester) async {
      final capela = ComunidadeModel(comuId: 4, comuNome: 'Capela Velha', ctipId: 2, usuaId: _usuario);
      await montar(tester, criar(_FakeComunidadeRepository([_matriz, _grupo, capela])));

      Icon iconeDoCard(String nome) => tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(of: find.text(nome), matching: find.byType(Card)),
          matching: find.descendant(of: find.byType(CircleAvatar), matching: find.byType(Icon)),
        ),
      );
      expect(iconeDoCard('Paróquia Matriz').icon, IconsMap.mdiIcons['home-group']);
      expect(iconeDoCard('Grupo de Oração').icon, IconsMap.mdiIcons['church'], reason: 'sem tipo');
      expect(iconeDoCard('Capela Velha').icon, IconsMap.mdiIcons['church'], reason: "'cathedral' não está no mapa");
    });

    testWidgets('mostra a aba "Minhas comunidades" com as comunidades e o botão de adicionar', (tester) async {
      await montar(tester, criar(_FakeComunidadeRepository([_matriz, _capela])));

      expect(find.text('comunidades'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'minhasComunidades'), findsOneWidget);
      expect(find.text('Paróquia Matriz'), findsOneWidget);
      expect(find.text('Paróquia · Católica'), findsOneWidget);
      expect(find.text('novaComunidade'), findsOneWidget);
    });

    testWidgets('a aba "Endereços" carrega só ao ser aberta, na primeira comunidade, com "Novo endereço"', (
      tester,
    ) async {
      final enderecos = _FakeComunidadeEnderecoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz, _grupo])), enderecos: enderecos);
      expect(enderecos.consultas, isEmpty);

      await abrirAba(tester, 'enderecos');

      expect(enderecos.consultas, [_grupo.comuId], reason: '"Grupo de Oração" vem primeiro, por nome');
      expect(find.text('nenhumEnderecoCadastrado'), findsOneWidget);
      expect(find.text('novoEndereco'), findsOneWidget);
      expect(find.text('novaComunidade'), findsNothing);
    });

    testWidgets('"Endereços" no menu da comunidade abre a aba com ela selecionada', (tester) async {
      final enderecos = _FakeComunidadeEnderecoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz, _grupo])), enderecos: enderecos);

      await tester.tap(find.byTooltip('acoes').last); // "Paróquia Matriz" é o segundo card
      await tester.pumpAndSettle();
      await tester.tap(find.text('enderecos').last);
      await tester.pumpAndSettle();

      expect(enderecos.consultas, [_matriz.comuId]);
      expect(find.text('Praça da Sé, 1'), findsOneWidget);
      expect(find.text('São Paulo - SP'), findsOneWidget);
    });

    testWidgets('"Novo endereço" inclui na comunidade selecionada', (tester) async {
      final enderecos = _FakeComunidadeEnderecoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz])), enderecos: enderecos);
      await abrirAba(tester, 'enderecos');

      await tester.tap(find.text('novoEndereco'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'cep'), '01310100');
      await tester.enterText(find.widgetWithText(TextField, 'logradouro'), 'Avenida Paulista');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.text('municipioObrigatorio'), findsOneWidget, reason: 'falta o município');

      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'estado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SP · São Paulo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'municipio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('São Paulo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(enderecos.gravados.single.comuId, _matriz.comuId);
      expect(enderecos.gravados.single.muniId, 3550308);
      expect(find.text('Avenida Paulista'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'registroSalvo'), findsOneWidget);
    });

    testWidgets('excluir endereço pelo menu do card pede confirmação e remove', (tester) async {
      final enderecos = _FakeComunidadeEnderecoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz])), enderecos: enderecos);
      await abrirAba(tester, 'enderecos');

      await tester.tap(find.byTooltip('acoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(enderecos.excluidos, [1]);
      expect(find.text('nenhumEnderecoCadastrado'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'registroExcluido'), findsOneWidget);
    });

    testWidgets('incluir uma comunidade faz a aba "Endereços" recarregar na próxima abertura', (tester) async {
      final enderecos = _FakeComunidadeEnderecoRepository();
      final viewModel = criar(_FakeComunidadeRepository([_matriz]));
      await montar(tester, viewModel, enderecos: enderecos);

      await abrirAba(tester, 'enderecos');
      await abrirAba(tester, 'minhasComunidades');
      expect(enderecos.consultas, hasLength(1));

      await viewModel.salvarCommand.execute(const ComunidadeModel(comuNome: 'Nova', ctipId: 1, cdenId: 2));
      await tester.pumpAndSettle();
      await abrirAba(tester, 'enderecos');

      expect(enderecos.consultas, hasLength(2));
      await tester.tap(find.text('Paróquia Matriz'));
      await tester.pumpAndSettle();
      expect(find.text('Nova'), findsWidgets, reason: 'a nova comunidade aparece na seleção');
    });

    testWidgets('a aba "Contatos" carrega só ao ser aberta, com "Novo contato"', (tester) async {
      final contatos = _FakeComunidadeContatoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz, _grupo])), contatos: contatos);
      expect(contatos.consultas, isEmpty);

      await abrirAba(tester, 'contatos');

      expect(contatos.consultas, [_grupo.comuId], reason: '"Grupo de Oração" vem primeiro, por nome');
      expect(find.text('nenhumContatoCadastrado'), findsOneWidget);
      expect(find.text('novoContato'), findsOneWidget);
    });

    testWidgets('"Contatos" no menu da comunidade abre a aba com ela selecionada', (tester) async {
      final contatos = _FakeComunidadeContatoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz, _grupo])), contatos: contatos);

      await tester.tap(find.byTooltip('acoes').last); // "Paróquia Matriz" é o segundo card
      await tester.pumpAndSettle();
      await tester.tap(find.text('contatos').last);
      await tester.pumpAndSettle();

      expect(contatos.consultas, [_matriz.comuId]);
      expect(find.text('secretaria@matriz.org'), findsOneWidget);
    });

    testWidgets('"Novo contato" valida os campos e inclui na comunidade selecionada', (tester) async {
      final contatos = _FakeComunidadeContatoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz])), contatos: contatos);
      await abrirAba(tester, 'contatos');

      await tester.tap(find.text('novoContato'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.text('contatoObrigatorio'), findsOneWidget, reason: 'nenhum campo preenchido');

      await tester.enterText(find.widgetWithText(TextField, 'whatsapp'), '61 9999');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.text('telefoneInvalido'), findsOneWidget, reason: 'erro no próprio campo');
      expect(contatos.gravados, isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'whatsapp'), '(61) 99999-4444');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(contatos.gravados.single.comuId, _matriz.comuId);
      expect(contatos.gravados.single.cconWhatsapp, '61999994444');
      expect(find.text('(61) 99999-4444'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'registroSalvo'), findsOneWidget);
    });

    testWidgets('excluir contato pelo menu do card pede confirmação e remove', (tester) async {
      final contatos = _FakeComunidadeContatoRepository();
      await montar(tester, criar(_FakeComunidadeRepository([_matriz])), contatos: contatos);
      await abrirAba(tester, 'contatos');

      await tester.tap(find.byTooltip('acoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(contatos.excluidos, [1]);
      expect(find.text('nenhumContatoCadastrado'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'registroExcluido'), findsOneWidget);
    });

    testWidgets('o menu da comunidade tem "Usuários" (abre a tela de usuários)', (tester) async {
      await montar(tester, criar(_FakeComunidadeRepository([_matriz])));
      await tester.tap(find.byTooltip('acoes'));
      await tester.pumpAndSettle();
      expect(find.text('usuarios'), findsOneWidget);
    });

    testWidgets('lista vazia mostra nenhumaComunidadeCadastrada', (tester) async {
      await montar(tester, criar(_FakeComunidadeRepository()));
      expect(find.text('nenhumaComunidadeCadastrada'), findsOneWidget);
    });

    testWidgets('falha no primeiro carregamento mostra a mensagem e tenta novamente', (tester) async {
      final repository = _FakeComunidadeRepository([_grupo])
        ..respostasLista.add(Result.error(HttpServiceException(message: 'erroGeralApi', code: 500)));
      await montar(tester, criar(repository));

      expect(find.text('erroGeralApi'), findsOneWidget);
      await tester.tap(find.text('tentarNovamente'));
      await tester.pumpAndSettle();
      expect(find.text('Grupo de Oração'), findsOneWidget);
    });

    testWidgets('falha na atualização mantém a lista e mostra SnackBar', (tester) async {
      final repository = _FakeComunidadeRepository([_grupo]);
      await montar(tester, criar(repository));
      repository.respostasLista.add(Result.error(HandledException(message: 'formatoComunidadeInvalido')));

      await tester.tap(find.byTooltip('atualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Grupo de Oração'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'formatoComunidadeInvalido'), findsOneWidget);
    });

    testWidgets('o botão inferior inclui uma comunidade pelo formulário', (tester) async {
      final repository = _FakeComunidadeRepository([_matriz]);
      await montar(tester, criar(repository));

      await tester.tap(find.text('novaComunidade'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // sem tipo e denominação o formulário mostra o problema e não fecha
      await tester.enterText(find.widgetWithText(TextField, 'nome'), 'Comunidade Nova');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.text('tipoObrigatorio'), findsOneWidget);

      await escolher(tester, 'tipo', 'Capela');
      await escolher(tester, 'denominacao', 'Católica');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.gravados.single.$1, 'incluir');
      expect(find.text('Comunidade Nova'), findsOneWidget);
      expect(find.widgetWithText(SnackBar, 'registroSalvo'), findsOneWidget);
    });

    testWidgets('tocar no card abre o formulário preenchido e altera', (tester) async {
      final repository = _FakeComunidadeRepository([_matriz]);
      await montar(tester, criar(repository));

      await tester.tap(find.text('Paróquia Matriz'));
      await tester.pumpAndSettle();
      expect(find.text('editarComunidade'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'nome'), 'Matriz Nova');
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(repository.gravados.single.$1, 'alterar');
      expect(repository.gravados.single.$2.comuId, 1);
      expect(find.text('Matriz Nova'), findsOneWidget);
    });

    testWidgets('erro ao gravar abre o aviso de erro', (tester) async {
      final repository = _FakeComunidadeRepository([_matriz])
        ..erroGravar = HttpServiceException(message: 'dadosInvalidos', code: 400);
      await montar(tester, criar(repository));

      await tester.tap(find.text('Paróquia Matriz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();

      expect(find.text('dadosInvalidos'), findsOneWidget);
    });

    testWidgets('excluir pelo menu do card pede confirmação e remove', (tester) async {
      final repository = _FakeComunidadeRepository([_matriz, _grupo]);
      await montar(tester, criar(repository));

      await tester.tap(find.byTooltip('acoes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('excluir'));
      await tester.pumpAndSettle();
      expect(find.text('confirmarExclusao'), findsOneWidget);

      // o botão do aviso mostra o texto em maiúsculas
      await tester.tap(find.text('EXCLUIR'));
      await tester.pumpAndSettle();

      expect(repository.excluidos, [_grupo.comuId], reason: 'o primeiro card é "Grupo de Oração", por nome');
      expect(find.text('Grupo de Oração'), findsNothing);
      expect(find.widgetWithText(SnackBar, 'registroExcluido'), findsOneWidget);
    });
  });
}
