// To parse this JSON data, do
//
//     final usuarioDispositivoBodyModel = usuarioDispositivoBodyModelFromJson(jsonString);

import 'dart:convert';

UsuarioDispositivoBodyModel usuarioDispositivoBodyModelFromJson(String str) =>
    UsuarioDispositivoBodyModel.fromJson(json.decode(str));

String usuarioDispositivoBodyModelToJson(UsuarioDispositivoBodyModel data) => json.encode(data.toJson());

class UsuarioDispositivoBodyModel {
  final int udisId;
  final int emprId;
  final String udisDeviceId;
  final String udisNome;
  final String udisSistemaOperacional;
  final String udloIp;

  UsuarioDispositivoBodyModel({
    required this.udisId,
    required this.emprId,
    required this.udisDeviceId,
    required this.udisNome,
    required this.udisSistemaOperacional,
    required this.udloIp,
  });

  factory UsuarioDispositivoBodyModel.fromJson(Map<String, dynamic> json) => UsuarioDispositivoBodyModel(
    udisId: json['udisId'],
    emprId: json['emprId'],
    udisDeviceId: json['udisDeviceId'],
    udisNome: json['udisNome'],
    udisSistemaOperacional: json['udisSistemaOperacional'],
    udloIp: '',
  );

  Map<String, dynamic> toJson() => {
    'udisId': udisId,
    'emprId': emprId,
    'udisDeviceId': udisDeviceId,
    'udisNome': udisNome,
    'udisSistemaOperacional': udisSistemaOperacional,
    'udloIp': udloIp,
  };
}
