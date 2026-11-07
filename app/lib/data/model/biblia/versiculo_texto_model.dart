import 'json_reader.dart';

/// Versículo do capítulo em leitura (`GET /v1/biblia/capitulo/:versaId/:livrId/:capiNumero`).
class VersiculoTextoModel {
  const VersiculoTextoModel({
    required this.versId,
    required this.versNumero,
    required this.versTexto,
    required this.livrId,
    required this.livrNome,
    required this.capiNumero,
  });

  final int versId;
  final int versNumero;
  final String versTexto;
  final int livrId;
  final String livrNome;
  final int capiNumero;

  /// Referência curta, ex.: "João 3:16".
  String get referencia => '$livrNome $capiNumero:$versNumero';

  factory VersiculoTextoModel.fromJson(Map<String, dynamic> json) => VersiculoTextoModel(
    versId: JsonReader.inteiro(json, 'versId', 'vers_id'),
    versNumero: JsonReader.inteiro(json, 'versNumero', 'vers_numero'),
    versTexto: JsonReader.texto(json, 'versTexto', 'vers_texto'),
    livrId: JsonReader.inteiro(json, 'livrId', 'livr_id'),
    livrNome: JsonReader.texto(json, 'livrNome', 'livr_nome'),
    capiNumero: JsonReader.inteiro(json, 'capiNumero', 'capi_numero'),
  );
}
