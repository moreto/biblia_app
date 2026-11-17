import '../biblia/json_reader.dart';

/// Item da busca no dicionário (`GET /v1/dicionario/busca?texto=&limite=`): palavra, homônimo e a classe e a
/// definição da primeira acepção.
///
/// A grafia é a do original (1913) e o itálico vem marcado com `_sublinhados_`.
class DicionarioBuscaModel {
  const DicionarioBuscaModel({
    required this.dverId,
    required this.dverPalavra,
    this.dverHomonimo,
    this.dverLetra,
    this.daceClasse,
    this.daceDefinicao,
    this.semelhanca,
  });

  final int dverId;
  final String dverPalavra;

  /// Número do homônimo; nulo quando a palavra não tem homônimos.
  final int? dverHomonimo;
  final String? dverLetra;

  /// Classe gramatical da primeira acepção (m., f., adj....); pode vir nula.
  final String? daceClasse;

  /// Definição da primeira acepção.
  final String? daceDefinicao;

  /// Semelhança com o texto buscado (0 a 1, trigramas).
  final double? semelhanca;

  factory DicionarioBuscaModel.fromJson(Map<String, dynamic> json) => DicionarioBuscaModel(
    dverId: JsonReader.inteiro(json, 'dverId', 'dver_id'),
    dverPalavra: JsonReader.texto(json, 'dverPalavra', 'dver_palavra'),
    dverHomonimo: JsonReader.inteiroOpcional(json, 'dverHomonimo', 'dver_homonimo'),
    dverLetra: JsonReader.textoOpcional(json, 'dverLetra', 'dver_letra'),
    daceClasse: JsonReader.textoOpcional(json, 'daceClasse', 'dace_classe'),
    daceDefinicao: JsonReader.textoOpcional(json, 'daceDefinicao', 'dace_definicao'),
    semelhanca: switch (json['semelhanca']) {
      final num valor => valor.toDouble(),
      final String valor => double.tryParse(valor),
      _ => null,
    },
  );

  Map<String, dynamic> toJson() => {
    'dverId': dverId,
    'dverPalavra': dverPalavra,
    'dverHomonimo': dverHomonimo,
    'dverLetra': dverLetra,
    'daceClasse': daceClasse,
    'daceDefinicao': daceDefinicao,
    'semelhanca': semelhanca,
  };
}
