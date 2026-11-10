import '../biblia/json_reader.dart';

/// Dispositivo do usuário (`public.usuario_dispositivo`), enviado e devolvido por `POST /v1/usuario-dispositivo`.
///
/// [udloIp] só vai no envio (log de acesso); [udisId] e [usuaId] só vêm na resposta.
class UsuarioDispositivoModel {
  const UsuarioDispositivoModel({
    this.udisId,
    this.usuaId,
    required this.udisDeviceId,
    required this.udisNome,
    required this.udisSistemaOperacional,
    this.udloIp,
  });

  final int? udisId;
  final int? usuaId;
  final String udisDeviceId;
  final String udisNome;
  final String udisSistemaOperacional;
  final String? udloIp;

  factory UsuarioDispositivoModel.fromJson(Map<String, dynamic> json) => UsuarioDispositivoModel(
    udisId: JsonReader.inteiroOpcional(json, 'udisId', 'udis_id'),
    usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
    udisDeviceId: JsonReader.texto(json, 'udisDeviceId', 'udis_device_id'),
    udisNome: JsonReader.texto(json, 'udisNome', 'udis_nome'),
    udisSistemaOperacional: JsonReader.texto(json, 'udisSistemaOperacional', 'udis_sistema_operacional'),
    udloIp: JsonReader.textoOpcional(json, 'udloIp', 'udlo_ip'),
  );

  /// Corpo do POST (campos nulos são removidos pelo DioProvider).
  Map<String, dynamic> toJson() => {
    'udisDeviceId': udisDeviceId,
    'udisNome': udisNome,
    'udisSistemaOperacional': udisSistemaOperacional,
    'udloIp': udloIp,
  };
}
