import 'json_reader.dart';

/// Capítulo do índice da versão (`GET /v1/biblia/indice/:versaId`), com a quantidade de versículos disponíveis.
class IndiceCapituloModel {
  const IndiceCapituloModel({
    required this.testId,
    required this.livrId,
    required this.livrNome,
    required this.capiNumero,
    required this.versTotal,
  });

  final int testId;
  final int livrId;
  final String livrNome;
  final int capiNumero;

  /// Versículos do capítulo na versão; 0 quando a versão não tem o capítulo.
  final int versTotal;

  factory IndiceCapituloModel.fromJson(Map<String, dynamic> json) => IndiceCapituloModel(
    testId: JsonReader.inteiro(json, 'testId', 'test_id'),
    livrId: JsonReader.inteiro(json, 'livrId', 'livr_id'),
    livrNome: JsonReader.texto(json, 'livrNome', 'livr_nome'),
    capiNumero: JsonReader.inteiro(json, 'capiNumero', 'capi_numero'),
    versTotal: JsonReader.inteiroOpcional(json, 'versTotal', 'vers_total') ?? 0,
  );
}
