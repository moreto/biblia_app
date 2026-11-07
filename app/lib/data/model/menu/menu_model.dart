// To parse this JSON data, do
//
//     final menuModel = menuModelFromJson(jsonString);

import 'dart:convert';

MenuModel menuModelFromJson(String str) => MenuModel.fromJson(json.decode(str));

String menuModelToJson(MenuModel data) => json.encode(data.toJson());

class MenuModel {
  final List<Menu> menu;

  MenuModel({required this.menu});

  factory MenuModel.fromJson(Map<String, dynamic> json) =>
      MenuModel(menu: List<Menu>.from(json['menu'].map((x) => Menu.fromJson(x))));

  Map<String, dynamic> toJson() => {'menu': List<dynamic>.from(menu.map((x) => x.toJson()))};
}

class Menu {
  final int menuId;
  final List<Menu>? children;
  final String menuNome;
  final String menuChave;
  final String menuIcone;
  final int menuSequencia;
  final String? menuRota;

  Menu({
    required this.menuId,
    this.children,
    required this.menuNome,
    required this.menuChave,
    required this.menuIcone,
    required this.menuSequencia,
    this.menuRota,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
    menuId: json['menuId'],
    children: json['children'] == null ? [] : List<Menu>.from(json['children']!.map((x) => Menu.fromJson(x))),
    menuNome: json['menuNome'],
    menuChave: json['menuChave'],
    menuIcone: json['menuIcone'],
    menuSequencia: json['menuSequencia'],
    menuRota: json['menuRota'],
  );

  Map<String, dynamic> toJson() => {
    'menuId': menuId,
    'children': children == null ? [] : List<dynamic>.from(children!.map((x) => x.toJson())),
    'menuNome': menuNome,
    'menuChave': menuChave,
    'menuIcone': menuIcone,
    'menuSequencia': menuSequencia,
    'menuRota': menuRota,
  };
}
