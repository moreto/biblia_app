import 'dart:convert';

import '../biblia/json_reader.dart';

UsuarioDetalheModel usuarioDetalheModelFromJson(String str) => UsuarioDetalheModel.fromJson(json.decode(str));

String usuarioDetalheModelToJson(UsuarioDetalheModel data) => json.encode(data.toJson());

/// Detalhe do usuário do token (`GET /v1/usuario/usuario-detalhe-by-id` e `PUT /v1/usuario/usuario-detalhe`):
/// dados de `public.usuario` (id, uuid, e-mail e situação) e de `public.usuario_detalhe` (nome completo e nome de
/// usuário). Nome e usuário ficam vazios se o detalhe ainda não existir; a empresa é opcional (a API atual não a
/// devolve).
class UsuarioDetalheModel {
  final int usuaId;
  final String usuaUuid;
  final String usuaEmail;
  final bool usuaAtivo;
  final String udetNome;
  final String udetUsuario;
  final int? emprId;
  final String? emprNome;

  const UsuarioDetalheModel({
    required this.usuaId,
    required this.usuaUuid,
    required this.usuaEmail,
    required this.usuaAtivo,
    required this.udetNome,
    required this.udetUsuario,
    this.emprId,
    this.emprNome,
  });

  /// Aceita camelCase ou snake_case; `usuaId` e `usuaEmail` são obrigatórios (senão [FormatException]).
  factory UsuarioDetalheModel.fromJson(Map<String, dynamic> json) => UsuarioDetalheModel(
    usuaId: JsonReader.inteiro(json, 'usuaId', 'usua_id'),
    usuaUuid: JsonReader.textoOpcional(json, 'usuaUuid', 'usua_uuid') ?? '',
    usuaEmail: JsonReader.texto(json, 'usuaEmail', 'usua_email'),
    usuaAtivo: switch (json['usuaAtivo'] ?? json['usua_ativo']) {
      null => false,
      final bool valor => valor,
      _ => throw const FormatException('campoInvalido', 'usuaAtivo'),
    },
    udetNome: JsonReader.textoOpcional(json, 'udetNome', 'udet_nome') ?? '',
    udetUsuario: JsonReader.textoOpcional(json, 'udetUsuario', 'udet_usuario') ?? '',
    emprId: JsonReader.inteiroOpcional(json, 'emprId', 'empr_id'),
    emprNome: JsonReader.textoOpcional(json, 'emprNome', 'empr_nome'),
  );

  Map<String, dynamic> toJson() => {
    'usuaId': usuaId,
    'usuaUuid': usuaUuid,
    'usuaEmail': usuaEmail,
    'usuaAtivo': usuaAtivo,
    'udetNome': udetNome,
    'udetUsuario': udetUsuario,
    'emprId': emprId,
    'emprNome': emprNome,
  };
}

/// Corpo de `PUT /v1/usuario/usuario-detalhe`.
class UsuarioDetalheBodyModel {
  const UsuarioDetalheBodyModel({required this.udetNome, required this.udetUsuario});

  final String udetNome;
  final String udetUsuario;

  Map<String, dynamic> toJson() => {'udetNome': udetNome, 'udetUsuario': udetUsuario};
}
