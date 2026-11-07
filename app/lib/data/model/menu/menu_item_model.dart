/// Item de menu (`public.menu`) usado na manutenção dos menus.
/// `menuParentId` nulo indica item raiz; [children] vem preenchido na hierarquia de `GET /v1/menu`.
class MenuItemModel {
  const MenuItemModel({
    this.menuId,
    required this.menuNome,
    required this.menuChave,
    this.menuIcone,
    this.menuSequencia,
    this.menuParentId,
    this.menuRota,
    this.menuAtivo = true,
    this.children = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int? menuId;
  final String menuNome;
  final String menuChave;
  final String? menuIcone;
  final int? menuSequencia;
  final int? menuParentId;
  final String? menuRota;
  final bool menuAtivo;
  final List<MenuItemModel> children;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isNovo => menuId == null;

  /// [parentId] completa o pai dos filhos da hierarquia, que não trazem `menuParentId`.
  factory MenuItemModel.fromJson(Map<String, dynamic> json, {int? parentId}) {
    final menuId = ((json['menuId'] ?? json['menu_id']) as num).toInt();
    final menuSequencia = json['menuSequencia'] ?? json['menu_sequencia'];
    final menuParentId = json['menuParentId'] ?? json['menu_parent_id'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'];
    final children = json['children'];

    return MenuItemModel(
      menuId: menuId,
      menuNome: (json['menuNome'] ?? json['menu_nome']) as String,
      menuChave: (json['menuChave'] ?? json['menu_chave']) as String,
      menuIcone: (json['menuIcone'] ?? json['menu_icone']) as String?,
      menuSequencia: (menuSequencia as num?)?.toInt(),
      menuParentId: (menuParentId as num?)?.toInt() ?? parentId,
      menuRota: (json['menuRota'] ?? json['menu_rota']) as String?,
      menuAtivo: (json['menuAtivo'] ?? json['menu_ativo']) as bool? ?? true,
      children: children is List
          ? children
                .map((child) => MenuItemModel.fromJson(Map<String, dynamic>.from(child as Map), parentId: menuId))
                .toList(growable: false)
          : const [],
      createdAt: createdAt == null ? null : DateTime.parse(createdAt as String),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt as String),
    );
  }

  /// Corpo de POST/PUT `/v1/menu` (sem `children`).
  Map<String, dynamic> toJson() => {
    'menuId': menuId,
    'menuNome': menuNome,
    'menuChave': menuChave,
    'menuIcone': menuIcone,
    'menuSequencia': menuSequencia,
    'menuParentId': menuParentId,
    'menuRota': menuRota,
    'menuAtivo': menuAtivo,
  };

  MenuItemModel copyWith({
    int? menuId,
    String? menuNome,
    String? menuChave,
    String? menuIcone,
    int? menuSequencia,
    int? menuParentId,
    String? menuRota,
    bool? menuAtivo,
    List<MenuItemModel>? children,
  }) => MenuItemModel(
    menuId: menuId ?? this.menuId,
    menuNome: menuNome ?? this.menuNome,
    menuChave: menuChave ?? this.menuChave,
    menuIcone: menuIcone ?? this.menuIcone,
    menuSequencia: menuSequencia ?? this.menuSequencia,
    menuParentId: menuParentId ?? this.menuParentId,
    menuRota: menuRota ?? this.menuRota,
    menuAtivo: menuAtivo ?? this.menuAtivo,
    children: children ?? this.children,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Item de menu posicionado na lista achatada da hierarquia: [nivel] 0 = raiz.
class MenuNivelModel {
  const MenuNivelModel({required this.menu, required this.nivel});

  final MenuItemModel menu;
  final int nivel;

  bool get possuiFilhos => menu.children.isNotEmpty;
}
