import '../biblia/json_reader.dart';

/// Verbete completo do dicionário (`GET /v1/dicionario/palavra/:palavra`, um item por homônimo): palavra,
/// pronúncia, etimologia e as acepções.
///
/// Fonte: Novo Diccionário da Língua Portuguesa, de Cândido de Figueiredo (1913). Textos na grafia original; o
/// itálico vem marcado com `_sublinhados_` e os exemplos entre « ».
class DicionarioVerbeteModel {
  const DicionarioVerbeteModel({
    required this.dverId,
    this.dverChave,
    required this.dverPalavra,
    this.dverLetra,
    this.dverHomonimo,
    this.dverPronuncia,
    this.dverEtimologia,
    this.dverEtimologiaOrigem,
    this.dverAsterisco = false,
    this.dverChaveta = false,
    this.acepcoes = const [],
  });

  final int dverId;
  final String? dverChave;
  final String dverPalavra;
  final String? dverLetra;

  /// Número do homônimo; nulo quando a palavra não tem homônimos.
  final int? dverHomonimo;

  /// Pronúncia de parte da palavra (ex.: `grê` em Allegreto).
  final String? dverPronuncia;
  final String? dverEtimologia;

  /// Língua ou tipo de origem (lat, gr, fr, ár, nome...).
  final String? dverEtimologiaOrigem;
  final bool dverAsterisco;

  /// Termo estrangeiro (marca de chaveta no original, como allegro).
  final bool dverChaveta;

  /// Acepções na ordem de `daceSeq`.
  final List<DicionarioAcepcaoModel> acepcoes;

  factory DicionarioVerbeteModel.fromJson(Map<String, dynamic> json) => DicionarioVerbeteModel(
    dverId: JsonReader.inteiro(json, 'dverId', 'dver_id'),
    dverChave: JsonReader.textoOpcional(json, 'dverChave', 'dver_chave'),
    dverPalavra: JsonReader.texto(json, 'dverPalavra', 'dver_palavra'),
    dverLetra: JsonReader.textoOpcional(json, 'dverLetra', 'dver_letra'),
    dverHomonimo: JsonReader.inteiroOpcional(json, 'dverHomonimo', 'dver_homonimo'),
    dverPronuncia: JsonReader.textoOpcional(json, 'dverPronuncia', 'dver_pronuncia'),
    dverEtimologia: JsonReader.textoOpcional(json, 'dverEtimologia', 'dver_etimologia'),
    dverEtimologiaOrigem: JsonReader.textoOpcional(json, 'dverEtimologiaOrigem', 'dver_etimologia_origem'),
    dverAsterisco: _booleano(json, 'dverAsterisco', 'dver_asterisco'),
    dverChaveta: _booleano(json, 'dverChaveta', 'dver_chaveta'),
    acepcoes: _lista(json['acepcoes'], DicionarioAcepcaoModel.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'dverId': dverId,
    'dverChave': dverChave,
    'dverPalavra': dverPalavra,
    'dverLetra': dverLetra,
    'dverHomonimo': dverHomonimo,
    'dverPronuncia': dverPronuncia,
    'dverEtimologia': dverEtimologia,
    'dverEtimologiaOrigem': dverEtimologiaOrigem,
    'dverAsterisco': dverAsterisco,
    'dverChaveta': dverChaveta,
    'acepcoes': [for (final a in acepcoes) a.toJson()],
  };
}

/// Sentido de um verbete: classe gramatical, definição, rótulos de uso e remissões "(V. termo)".
class DicionarioAcepcaoModel {
  const DicionarioAcepcaoModel({
    required this.daceId,
    required this.daceSeq,
    this.daceClasse,
    required this.daceDefinicao,
    this.daceAsterisco = false,
    this.usos = const [],
    this.remissoes = const [],
  });

  final int daceId;
  final int daceSeq;

  /// Classe gramatical abreviada (m., f., adj., v. t....); nula quando vale a da acepção anterior.
  final String? daceClasse;
  final String daceDefinicao;
  final bool daceAsterisco;
  final List<DicionarioUsoModel> usos;
  final List<DicionarioRemissaoModel> remissoes;

  factory DicionarioAcepcaoModel.fromJson(Map<String, dynamic> json) => DicionarioAcepcaoModel(
    daceId: JsonReader.inteiro(json, 'daceId', 'dace_id'),
    daceSeq: JsonReader.inteiro(json, 'daceSeq', 'dace_seq'),
    daceClasse: JsonReader.textoOpcional(json, 'daceClasse', 'dace_classe'),
    daceDefinicao: JsonReader.texto(json, 'daceDefinicao', 'dace_definicao'),
    daceAsterisco: _booleano(json, 'daceAsterisco', 'dace_asterisco'),
    usos: _lista(json['usos'], DicionarioUsoModel.fromJson),
    remissoes: _lista(json['remissoes'], DicionarioRemissaoModel.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'daceId': daceId,
    'daceSeq': daceSeq,
    'daceClasse': daceClasse,
    'daceDefinicao': daceDefinicao,
    'daceAsterisco': daceAsterisco,
    'usos': [for (final u in usos) u.toJson()],
    'remissoes': [for (final r in remissoes) r.toJson()],
  };
}

/// Rótulo de uso de uma acepção: [dusoTipo] `registro` (Pop., Des., Prov.), `regiao` (Bras., Trasm.), `area`
/// (Med., Bot.) ou `observacao`.
class DicionarioUsoModel {
  const DicionarioUsoModel({required this.dusoTipo, required this.dusoTexto});

  final String dusoTipo;
  final String dusoTexto;

  factory DicionarioUsoModel.fromJson(Map<String, dynamic> json) => DicionarioUsoModel(
    dusoTipo: JsonReader.texto(json, 'dusoTipo', 'duso_tipo'),
    dusoTexto: JsonReader.texto(json, 'dusoTexto', 'duso_texto'),
  );

  Map<String, dynamic> toJson() => {'dusoTipo': dusoTipo, 'dusoTexto': dusoTexto};
}

/// Remissão "(V. termo)": [dverId] é o verbete de destino ou nulo se a palavra não existir no dicionário.
class DicionarioRemissaoModel {
  const DicionarioRemissaoModel({required this.dremTermo, this.dverId});

  final String dremTermo;
  final int? dverId;

  factory DicionarioRemissaoModel.fromJson(Map<String, dynamic> json) => DicionarioRemissaoModel(
    dremTermo: JsonReader.texto(json, 'dremTermo', 'drem_termo'),
    dverId: JsonReader.inteiroOpcional(json, 'dverId', 'dver_id'),
  );

  Map<String, dynamic> toJson() => {'dremTermo': dremTermo, 'dverId': dverId};
}

bool _booleano(Map<String, dynamic> json, String camel, String snake) => switch (json[camel] ?? json[snake]) {
  null => false,
  final bool valor => valor,
  _ => throw FormatException('campoInvalido', camel),
};

/// Lista de objetos; ausente vira lista vazia, outro tipo lança [FormatException].
List<T> _lista<T>(Object? valor, T Function(Map<String, dynamic>) fromJson) => switch (valor) {
  null => const [],
  final List lista => [
    for (final item in lista)
      if (item is Map) fromJson(Map<String, dynamic>.from(item)) else throw const FormatException('campoInvalido'),
  ],
  _ => throw const FormatException('campoInvalido'),
};
