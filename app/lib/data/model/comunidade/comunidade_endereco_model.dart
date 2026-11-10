import '../biblia/json_reader.dart';

/// Endereço de uma comunidade (`biblia.comunidade_endereco`), como devolvido por `/v1/comunidade-endereco/:comuId`.
///
/// [muniNome], [estaId] e [estaSigla] vêm de `public.municipio` e `public.estado` (nulos se a API não os devolver).
class ComunidadeEnderecoModel {
  const ComunidadeEnderecoModel({
    this.cendId,
    required this.comuId,
    required this.cendCep,
    required this.cendLogradouro,
    this.cendNumero,
    this.cendComplemento,
    this.cendBairro,
    required this.muniId,
    this.muniNome,
    this.estaId,
    this.estaSigla,
  });

  /// Nulo enquanto o endereço não foi gravado.
  final int? cendId;
  final int comuId;
  final String cendCep;
  final String cendLogradouro;
  final String? cendNumero;
  final String? cendComplemento;
  final String? cendBairro;
  final int muniId;
  final String? muniNome;

  /// Estado do município (para a seleção no formulário).
  final int? estaId;
  final String? estaSigla;

  factory ComunidadeEnderecoModel.fromJson(Map<String, dynamic> json) => ComunidadeEnderecoModel(
    cendId: JsonReader.inteiroOpcional(json, 'cendId', 'cend_id'),
    comuId: JsonReader.inteiro(json, 'comuId', 'comu_id'),
    cendCep: JsonReader.texto(json, 'cendCep', 'cend_cep'),
    cendLogradouro: JsonReader.texto(json, 'cendLogradouro', 'cend_logradouro'),
    cendNumero: JsonReader.textoOpcional(json, 'cendNumero', 'cend_numero'),
    cendComplemento: JsonReader.textoOpcional(json, 'cendComplemento', 'cend_complemento'),
    cendBairro: JsonReader.textoOpcional(json, 'cendBairro', 'cend_bairro'),
    muniId: JsonReader.inteiro(json, 'muniId', 'muni_id'),
    muniNome: JsonReader.textoOpcional(json, 'muniNome', 'muni_nome'),
    estaId: JsonReader.inteiroOpcional(json, 'estaId', 'esta_id'),
    estaSigla: JsonReader.textoOpcional(json, 'estaSigla', 'esta_sigla'),
  );

  /// Corpo do POST/PUT (campos nulos são removidos pelo DioProvider).
  Map<String, dynamic> toJson() => {
    'cendId': cendId,
    'comuId': comuId,
    'cendCep': cendCep,
    'cendLogradouro': cendLogradouro,
    'cendNumero': cendNumero,
    'cendComplemento': cendComplemento,
    'cendBairro': cendBairro,
    'muniId': muniId,
  };
}
