import 'package:commons/commons.dart';

import '../../../data/model/menu/menu_item_model.dart';
import '../repository/menu_repository.dart';

class MenuUseCase {
  MenuUseCase({required this.menuRepository}) {
    Log.print(super.runtimeType);
  }

  static const int kMenuNomeMaxLength = 60;
  static const int kMenuChaveMaxLength = 30;
  static const int kMenuIconeMaxLength = 90;
  static const int kMenuRotaMaxLength = 60;

  /// `GET /v1/menu` devolve só dois níveis (raiz e filhos): o pai de um item precisa ser raiz.
  static const int kMenuNivelMaximo = 2;

  final MenuRepository menuRepository;

  /// Hierarquia achatada em profundidade (pai seguido dos filhos), ordenada por sequência e nome em cada nível.
  Future<Result<List<MenuNivelModel>>> getMenus() async {
    final result = await menuRepository.getMenus();
    switch (result) {
      case Ok<List<MenuItemModel>>():
        final menus = <MenuNivelModel>[];
        _achatar(result.value, 0, menus);
        return Result.ok(List.unmodifiable(menus));
      case Error<List<MenuItemModel>>():
        return Result.error(result.error);
    }
  }

  void _achatar(List<MenuItemModel> itens, int nivel, List<MenuNivelModel> destino) {
    final ordenados = [...itens]..sort(_comparar);
    for (final item in ordenados) {
      final filhos = [...item.children]..sort(_comparar);
      destino.add(
        MenuNivelModel(
          menu: item.copyWith(children: filhos),
          nivel: nivel,
        ),
      );
      _achatar(filhos, nivel + 1, destino);
    }
  }

  int _comparar(MenuItemModel a, MenuItemModel b) {
    final sequencia = (a.menuSequencia ?? 1 << 30).compareTo(b.menuSequencia ?? 1 << 30);
    if (sequencia != 0) return sequencia;
    return a.menuNome.toLowerCase().compareTo(b.menuNome.toLowerCase());
  }

  /// Itens que ficam visíveis na lista: os filhos dos itens em [recolhidos] são ocultados.
  List<MenuNivelModel> visiveis(List<MenuNivelModel> menus, Set<int> recolhidos) {
    final visiveis = <MenuNivelModel>[];
    int? nivelOculto;
    for (final item in menus) {
      if (nivelOculto != null && item.nivel > nivelOculto) continue;
      nivelOculto = null;
      visiveis.add(item);
      if (item.possuiFilhos && recolhidos.contains(item.menu.menuId)) nivelOculto = item.nivel;
    }
    return visiveis;
  }

  /// Menus que podem ser pai de [menu]: só itens raiz, exceto o próprio item.
  /// Um item que já tem filhos não pode virar filho (passaria do nível máximo).
  List<MenuItemModel> opcoesPai(List<MenuNivelModel> menus, MenuItemModel? menu) {
    if (menu != null && menu.children.isNotEmpty) return const [];
    return menus
        .where((item) => item.nivel < kMenuNivelMaximo - 1 && item.menu.menuId != menu?.menuId)
        .map((item) => item.menu)
        .toList(growable: false);
  }

  /// Valida e normaliza; insere quando [MenuItemModel.menuId] é nulo, senão altera.
  Future<Result<MenuItemModel>> saveMenu(MenuItemModel menu) async {
    final nome = menu.menuNome.trim();
    if (nome.isEmpty) return Result.error(HandledException(message: 'nomeObrigatorio'));
    if (nome.length > kMenuNomeMaxLength) return Result.error(HandledException(message: 'nomeMaximo60'));

    final chave = menu.menuChave.trim();
    if (chave.isEmpty) return Result.error(HandledException(message: 'chaveObrigatoria'));
    if (chave.length > kMenuChaveMaxLength) return Result.error(HandledException(message: 'chaveMaximo30'));

    final icone = _opcional(menu.menuIcone);
    if (icone != null && icone.length > kMenuIconeMaxLength) {
      return Result.error(HandledException(message: 'iconeMaximo90'));
    }

    final rota = _opcional(menu.menuRota);
    if (rota != null && rota.length > kMenuRotaMaxLength) {
      return Result.error(HandledException(message: 'rotaMaximo60'));
    }
    if (rota != null && (!rota.startsWith('/') || rota.contains(' '))) {
      return Result.error(HandledException(message: 'rotaInvalida'));
    }

    if (menu.menuParentId != null && (menu.menuParentId == menu.menuId || menu.children.isNotEmpty)) {
      return Result.error(HandledException(message: 'menuPaiInvalido'));
    }

    final normalizado = MenuItemModel(
      menuId: menu.menuId,
      menuNome: nome,
      menuChave: chave,
      menuIcone: icone,
      menuSequencia: menu.menuSequencia,
      menuParentId: menu.menuParentId,
      menuRota: rota,
      menuAtivo: menu.menuAtivo,
    );
    final result = normalizado.isNovo
        ? await menuRepository.insertMenu(normalizado)
        : await menuRepository.updateMenu(normalizado);
    switch (result) {
      case Ok<MenuItemModel>():
        return Result.ok(result.value);
      case Error<MenuItemModel>():
        return Result.error(result.error);
    }
  }

  /// Itens com filhos não podem ser excluídos (a API responde 409 `menuPossuiFilhos`).
  Future<Result<int>> deleteMenu(MenuItemModel menu) async {
    final menuId = menu.menuId;
    if (menuId == null) return Result.error(HandledException(message: 'registroNaoEncontrado'));
    if (menu.children.isNotEmpty) return Result.error(HandledException(message: 'menuPossuiFilhos'));

    final result = await menuRepository.deleteMenu(menuId);
    switch (result) {
      case Ok<int>():
        return Result.ok(result.value);
      case Error<int>():
        return Result.error(result.error);
    }
  }

  String? _opcional(String? valor) {
    final texto = valor?.trim();
    return texto == null || texto.isEmpty ? null : texto;
  }
}
