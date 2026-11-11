import '../biblia/json_reader.dart';

/// Comunidade encontrada por estado/cidade (`GET /v1/comunidade?estaId=&muniId=`): dados da comunidade, do tipo
/// (nome e ícone `ctip_icone`), da denominação e do endereço que atendeu ao filtro.
class ComunidadeLocalModel {
  const ComunidadeLocalModel({
    required this.comuId,
    required this.comuNome,
    this.ctipNome,
    this.ctipIcone,
    this.cdenNome,
    this.cendLogradouro,
    this.cendNumero,
    this.cendComplemento,
    this.cendBairro,
    this.cendCep,
    required this.muniId,
    this.muniNome,
    required this.estaId,
    this.estaSigla,
  });

  final int comuId;
  final String comuNome;
  final String? ctipNome;

  /// Chave MDI do ícone do tipo (`IconsMap.mdiIcons`); nula se o tipo não tiver.
  final String? ctipIcone;
  final String? cdenNome;
  final String? cendLogradouro;

  /// Número do endereço (inteiro no banco; lido como texto).
  final String? cendNumero;
  final String? cendComplemento;
  final String? cendBairro;
  final String? cendCep;
  final int muniId;
  final String? muniNome;
  final int estaId;
  final String? estaSigla;

  factory ComunidadeLocalModel.fromJson(Map<String, dynamic> json) => ComunidadeLocalModel(
    comuId: JsonReader.inteiro(json, 'comuId', 'comu_id'),
    comuNome: JsonReader.texto(json, 'comuNome', 'comu_nome'),
    ctipNome: JsonReader.textoOpcional(json, 'ctipNome', 'ctip_nome'),
    ctipIcone: JsonReader.textoOpcional(json, 'ctipIcone', 'ctip_icone'),
    cdenNome: JsonReader.textoOpcional(json, 'cdenNome', 'cden_nome'),
    cendLogradouro: JsonReader.textoOpcional(json, 'cendLogradouro', 'cend_logradouro'),
    cendNumero: JsonReader.textoOpcional(json, 'cendNumero', 'cend_numero'),
    cendComplemento: JsonReader.textoOpcional(json, 'cendComplemento', 'cend_complemento'),
    cendBairro: JsonReader.textoOpcional(json, 'cendBairro', 'cend_bairro'),
    cendCep: JsonReader.textoOpcional(json, 'cendCep', 'cend_cep'),
    muniId: JsonReader.inteiro(json, 'muniId', 'muni_id'),
    muniNome: JsonReader.textoOpcional(json, 'muniNome', 'muni_nome'),
    estaId: JsonReader.inteiro(json, 'estaId', 'esta_id'),
    estaSigla: JsonReader.textoOpcional(json, 'estaSigla', 'esta_sigla'),
  );
}
