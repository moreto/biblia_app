import '../biblia/json_reader.dart';

/// Tipo de comunidade (`GET /v1/comunidade-tipo`).
class ComunidadeTipoModel {
  const ComunidadeTipoModel({required this.ctipId, required this.ctipNome});

  final int ctipId;
  final String ctipNome;

  factory ComunidadeTipoModel.fromJson(Map<String, dynamic> json) => ComunidadeTipoModel(
    ctipId: JsonReader.inteiro(json, 'ctipId', 'ctip_id'),
    ctipNome: JsonReader.texto(json, 'ctipNome', 'ctip_nome'),
  );
}
