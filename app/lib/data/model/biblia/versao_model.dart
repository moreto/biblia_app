import 'json_reader.dart';

/// Versão da Bíblia (`GET /v1/versao`).
class VersaoModel {
  const VersaoModel({required this.versaId, required this.versaCodigo, required this.versaNome});

  final int versaId;

  /// Sigla da versão, ex.: "ARC".
  final String versaCodigo;
  final String versaNome;

  factory VersaoModel.fromJson(Map<String, dynamic> json) => VersaoModel(
    versaId: JsonReader.inteiro(json, 'versaId', 'versa_id'),
    versaCodigo: JsonReader.texto(json, 'versaCodigo', 'versa_codigo'),
    versaNome: JsonReader.texto(json, 'versaNome', 'versa_nome'),
  );
}
