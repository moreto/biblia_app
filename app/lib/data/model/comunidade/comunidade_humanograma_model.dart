import '../biblia/json_reader.dart';

/// Pessoa do humanograma (liderança) de uma comunidade, com o cargo (`GET /v1/comunidade-humanograma-dto/:comuId`).
class ComunidadeHumanogramaModel {
  const ComunidadeHumanogramaModel({
    required this.chumId,
    required this.comuId,
    this.comuParentId,
    required this.chumNome,
    this.chcaId,
    this.chcaCargo,
  });

  final int chumId;
  final int comuId;

  /// Comunidade "mãe" na hierarquia; nula na raiz.
  final int? comuParentId;
  final String chumNome;
  final int? chcaId;
  final String? chcaCargo;

  factory ComunidadeHumanogramaModel.fromJson(Map<String, dynamic> json) => ComunidadeHumanogramaModel(
    chumId: JsonReader.inteiro(json, 'chumId', 'chum_id'),
    comuId: JsonReader.inteiro(json, 'comuId', 'comu_id'),
    comuParentId: JsonReader.inteiroOpcional(json, 'comuParentId', 'comu_parent_id'),
    chumNome: JsonReader.texto(json, 'chumNome', 'chum_nome'),
    chcaId: JsonReader.inteiroOpcional(json, 'chcaId', 'chca_id'),
    chcaCargo: JsonReader.textoOpcional(json, 'chcaCargo', 'chca_cargo'),
  );
}
