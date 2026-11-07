import 'package:app/data/model/menu/menu_item_model.dart';
import 'package:app/features/admin/menu/repository/menu_repository.dart';
import 'package:app/features/admin/menu/ui/menu_view.dart';
import 'package:app/features/admin/menu/ui/menu_viewmodel.dart';
import 'package:app/features/admin/menu/use_case/menu_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guarda os itens "planos" e devolve a hierarquia como `GET /v1/menu` (só ativos, dois níveis).
class _FakeMenuRepository implements MenuRepository {
  final List<MenuItemModel> itens = [
    const MenuItemModel(menuId: 1, menuNome: 'Configurações', menuChave: 'configuracao', menuSequencia: 2),
    const MenuItemModel(menuId: 3, menuNome: 'Home', menuChave: 'home', menuIcone: 'home', menuSequencia: 1),
    const MenuItemModel(
      menuId: 2,
      menuNome: 'Traduções',
      menuChave: 'traducao',
      menuSequencia: 2,
      menuParentId: 1,
      menuRota: '/traducao',
    ),
    const MenuItemModel(menuId: 4, menuNome: 'Logs', menuChave: 'log', menuSequencia: 1, menuParentId: 1),
  ];
  int _nextId = 100;

  @override
  Future<Result<List<MenuItemModel>>> getMenus() async {
    final ativos = itens.where((item) => item.menuAtivo);
    return Result.ok(
      ativos
          .where((item) => item.menuParentId == null)
          .map((raiz) => raiz.copyWith(children: ativos.where((f) => f.menuParentId == raiz.menuId).toList()))
          .toList(),
    );
  }

  @override
  Future<Result<MenuItemModel>> insertMenu(MenuItemModel menu) async {
    final novo = menu.copyWith(menuId: _nextId++);
    itens.add(novo);
    return Result.ok(novo);
  }

  @override
  Future<Result<MenuItemModel>> updateMenu(MenuItemModel menu) async {
    final index = itens.indexWhere((item) => item.menuId == menu.menuId);
    if (index < 0) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    itens[index] = menu;
    return Result.ok(menu);
  }

  @override
  Future<Result<int>> deleteMenu(int menuId) async {
    itens.removeWhere((item) => item.menuId == menuId);
    return Result.ok(menuId);
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
  late _FakeMenuRepository repository;
  late MenuUseCase useCase;

  setUp(() {
    repository = _FakeMenuRepository();
    useCase = MenuUseCase(menuRepository: repository);
  });

  Future<List<MenuNivelModel>> carregar() async => (await useCase.getMenus() as Ok<List<MenuNivelModel>>).value;

  group('MenuUseCase', () {
    test('achata a hierarquia: pai seguido dos filhos, ordenados por sequência', () async {
      final menus = await carregar();
      expect(menus.map((item) => item.menu.menuId), [3, 1, 4, 2]);
      expect(menus.map((item) => item.nivel), [0, 0, 1, 1]);
      expect(menus.firstWhere((item) => item.menu.menuId == 2).menu.menuParentId, 1);
    });

    test('oculta os filhos dos itens recolhidos', () async {
      final menus = await carregar();
      expect(useCase.visiveis(menus, {1}).map((item) => item.menu.menuId), [3, 1]);
    });

    test('opções de pai: só raízes, sem o próprio item; item com filhos não pode ter pai', () async {
      final menus = await carregar();
      final home = menus.firstWhere((item) => item.menu.menuId == 3).menu;
      final configuracoes = menus.firstWhere((item) => item.menu.menuId == 1).menu;
      final logs = menus.firstWhere((item) => item.menu.menuId == 4).menu;

      expect(useCase.opcoesPai(menus, home).map((item) => item.menuId), [1]);
      expect(useCase.opcoesPai(menus, logs).map((item) => item.menuId), [3, 1]);
      expect(useCase.opcoesPai(menus, configuracoes), isEmpty);
    });

    test('valida nome, chave e rota', () async {
      Future<Object?> erro(MenuItemModel menu) async => (await useCase.saveMenu(menu) as Error).error;

      expect(
        await erro(const MenuItemModel(menuNome: ' ', menuChave: 'x')),
        HandledException(message: 'nomeObrigatorio'),
      );
      expect(
        await erro(const MenuItemModel(menuNome: 'x', menuChave: '')),
        HandledException(message: 'chaveObrigatoria'),
      );
      expect(await erro(MenuItemModel(menuNome: 'x', menuChave: 'c' * 31)), HandledException(message: 'chaveMaximo30'));
      expect(
        await erro(const MenuItemModel(menuNome: 'x', menuChave: 'x', menuRota: 'sem-barra')),
        HandledException(message: 'rotaInvalida'),
      );
      expect(
        await erro(const MenuItemModel(menuId: 5, menuNome: 'x', menuChave: 'x', menuParentId: 5)),
        HandledException(message: 'menuPaiInvalido'),
      );
    });

    test('insere normalizando textos e grava opcionais vazios como nulos', () async {
      final result = await useCase.saveMenu(
        const MenuItemModel(menuNome: '  Novo ', menuChave: ' novo ', menuIcone: '  ', menuRota: ' '),
      );
      final value = (result as Ok<MenuItemModel>).value;
      expect(value.menuId, isNotNull);
      expect(value.menuNome, 'Novo');
      expect(value.menuChave, 'novo');
      expect(value.menuIcone, isNull);
      expect(value.menuRota, isNull);
    });

    test('não exclui item com filhos', () async {
      final menus = await carregar();
      final configuracoes = menus.firstWhere((item) => item.menu.menuId == 1).menu;
      final result = await useCase.deleteMenu(configuracoes);
      expect((result as Error).error, HandledException(message: 'menuPossuiFilhos'));
      expect(repository.itens.any((item) => item.menuId == 1), isTrue);
    });
  });

  group('MenuViewmodel', () {
    test('carrega e alterna recolhido', () async {
      final viewModel = MenuViewmodel(menuUseCase: useCase);
      await pumpEventQueue();

      expect(viewModel.menusVisiveis, hasLength(4));
      final configuracoes = viewModel.menus!.firstWhere((item) => item.menu.menuId == 1).menu;

      viewModel.alternarRecolhido(configuracoes);
      expect(viewModel.isRecolhido(configuracoes), isTrue);
      expect(viewModel.menusVisiveis!.map((item) => item.menu.menuId), [3, 1]);

      viewModel.alternarRecolhido(configuracoes);
      expect(viewModel.menusVisiveis, hasLength(4));
    });

    test('inclui submenu e recarrega a lista', () async {
      final viewModel = MenuViewmodel(menuUseCase: useCase);
      await pumpEventQueue();

      await viewModel.saveMenuCommand.execute(
        const MenuItemModel(menuNome: 'Menus', menuChave: 'menu', menuSequencia: 3, menuParentId: 1),
      );
      await pumpEventQueue();

      expect(viewModel.saveMenuCommand.completed, isTrue);
      expect(viewModel.menus!.map((item) => item.menu.menuId), [3, 1, 4, 2, 100]);
    });

    test('exclui item sem filhos', () async {
      final viewModel = MenuViewmodel(menuUseCase: useCase);
      await pumpEventQueue();

      final logs = viewModel.menus!.firstWhere((item) => item.menu.menuId == 4).menu;
      await viewModel.deleteMenuCommand.execute(logs);
      await pumpEventQueue();

      expect(viewModel.menus!.map((item) => item.menu.menuId), [3, 1, 2]);
    });
  });

  testWidgets('mostra a hierarquia e recolhe os filhos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          _TestLocalizationsDelegate(),
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: MenuView(viewModel: MenuViewmodel(menuUseCase: useCase)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Traduções'), findsOneWidget);

    await tester.tap(find.byTooltip('recolher'));
    await tester.pump();

    expect(find.text('Logs'), findsNothing);
    expect(find.text('Traduções'), findsNothing);
  });
}
