// To parse this JSON data, do
//
//     final usuarioDispositivoModel = usuarioDispositivoModelFromJson(jsonString);

import 'dart:convert';

UsuarioDispositivoModel usuarioDispositivoModelFromJson(String str) =>
    UsuarioDispositivoModel.fromJson(json.decode(str));

String usuarioDispositivoModelToJson(UsuarioDispositivoModel data) => json.encode(data.toJson());

class UsuarioDispositivoModel {
  final int udisId;
  final int emprId;
  final String udisDeviceId;
  final String udisNome;
  final String udisSistemaOperacional;

  UsuarioDispositivoModel({
    required this.udisId,
    required this.emprId,
    required this.udisDeviceId,
    required this.udisNome,
    required this.udisSistemaOperacional,
  });

  factory UsuarioDispositivoModel.fromJson(Map<String, dynamic> json) => UsuarioDispositivoModel(
    udisId: json['udisId'],
    emprId: json['emprId'],
    udisDeviceId: json['udisDeviceId'],
    udisNome: json['udisNome'],
    udisSistemaOperacional: json['udisSistemaOperacional'],
  );

  Map<String, dynamic> toJson() => {
    'udisId': udisId,
    'emprId': emprId,
    'udisDeviceId': udisDeviceId,
    'udisNome': udisNome,
    'udisSistemaOperacional': udisSistemaOperacional,
  };
}
