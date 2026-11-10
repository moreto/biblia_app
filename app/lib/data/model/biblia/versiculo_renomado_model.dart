import 'json_reader.dart';

/// Versículo de um renomado na versão escolhida (`GET /v1/versiculo-renomado/:renoId/:versaId`).
///
/// A API resolve a referência (livro, capítulo e número) pelo versículo gravado em `biblia.versiculo_renomado` e
/// devolve o texto e o [versId] do versículo de mesma referência na versão pedida ([versaId]).
class VersiculoRenomadoModel {
  const VersiculoRenomadoModel({
    required this.vrenId,
    required this.renoId,
    this.vrenSeq,
    required this.livrId,
    required this.livrNome,
    required this.capiNumero,
    required this.versId,
    required this.versNumero,
    required this.versTexto,
    required this.versaId,
  });

  final int vrenId;
  final int renoId;

  /// Ordem do versículo na lista do renomado; nulo vai para o fim.
  final int? vrenSeq;
  final int livrId;
  final String livrNome;
  final int capiNumero;

  /// Versículo na versão [versaId].
  final int versId;
  final int versNumero;
  final String versTexto;
  final int versaId;

  /// Referência curta, ex.: "João 3:16".
  String get referencia => '$livrNome $capiNumero:$versNumero';

  factory VersiculoRenomadoModel.fromJson(Map<String, dynamic> json) => VersiculoRenomadoModel(
    vrenId: JsonReader.inteiro(json, 'vrenId', 'vren_id'),
    renoId: JsonReader.inteiro(json, 'renoId', 'reno_id'),
    vrenSeq: JsonReader.inteiroOpcional(json, 'vrenSeq', 'vren_seq'),
    livrId: JsonReader.inteiro(json, 'livrId', 'livr_id'),
    livrNome: JsonReader.texto(json, 'livrNome', 'livr_nome'),
    capiNumero: JsonReader.inteiro(json, 'capiNumero', 'capi_numero'),
    versId: JsonReader.inteiro(json, 'versId', 'vers_id'),
    versNumero: JsonReader.inteiro(json, 'versNumero', 'vers_numero'),
    versTexto: JsonReader.texto(json, 'versTexto', 'vers_texto'),
    versaId: JsonReader.inteiro(json, 'versaId', 'versa_id'),
  );
}
