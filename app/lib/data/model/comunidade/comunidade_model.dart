import '../biblia/json_reader.dart';

/// Comunidade (`biblia.comunidade`), como devolvida por `/v1/comunidade`.
class ComunidadeModel {
  const ComunidadeModel({required this.comuId, required this.comuNome, this.ctipId, this.cdenId, this.usuaId});

  final int comuId;
  final String comuNome;

  /// Tipo (`/v1/comunidade-tipo`).
  final int? ctipId;

  /// Denominação (`/v1/comunidade-denominacao`).
  final int? cdenId;

  /// Usuário que cadastrou a comunidade.
  final int? usuaId;

  factory ComunidadeModel.fromJson(Map<String, dynamic> json) => ComunidadeModel(
    comuId: JsonReader.inteiro(json, 'comuId', 'comu_id'),
    comuNome: JsonReader.texto(json, 'comuNome', 'comu_nome'),
    ctipId: JsonReader.inteiroOpcional(json, 'ctipId', 'ctip_id'),
    cdenId: JsonReader.inteiroOpcional(json, 'cdenId', 'cden_id'),
    usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
  );

  Map<String, dynamic> toJson() => {
    'comuId': comuId,
    'comuNome': comuNome,
    'ctipId': ctipId,
    'cdenId': cdenId,
    'usuaId': usuaId,
  };
}
