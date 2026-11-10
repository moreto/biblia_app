import '../biblia/json_reader.dart';

/// Denominação de comunidade (`GET /v1/comunidade-denominacao`).
class ComunidadeDenominacaoModel {
  const ComunidadeDenominacaoModel({required this.cdenId, required this.cdenNome});

  final int cdenId;
  final String cdenNome;

  factory ComunidadeDenominacaoModel.fromJson(Map<String, dynamic> json) => ComunidadeDenominacaoModel(
    cdenId: JsonReader.inteiro(json, 'cdenId', 'cden_id'),
    cdenNome: JsonReader.texto(json, 'cdenNome', 'cden_nome'),
  );
}
