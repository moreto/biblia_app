import 'dart:convert';

import 'package:commons/commons.dart';
import 'package:flutter/painting.dart' show Color;

/// Cores das tags. [cor] é o tom base: o chip usa ele bem claro no fundo e cheio na bolinha, o que funciona nos
/// temas claro e escuro.
///
/// A ordem do enum é a das sugestões ao criar uma tag (as 8 primeiras antes, as novas depois); a paleta mostra
/// [paleta], agrupada por tom. Os nomes são gravados: não renomear.
enum CorTag {
  azul(Color(0xFF1E88E5)),
  verde(Color(0xFF43A047)),
  amarelo(Color(0xFFF9A825)),
  laranja(Color(0xFFFB8C00)),
  vermelho(Color(0xFFE53935)),
  rosa(Color(0xFFD81B60)),
  roxo(Color(0xFF8E24AA)),
  cinza(Color(0xFF757575)),
  anil(Color(0xFF3949AB)),
  ciano(Color(0xFF00ACC1)),
  turquesa(Color(0xFF00897B)),
  lima(Color(0xFF7CB342)),
  ambar(Color(0xFFFFB300)),
  vinho(Color(0xFF8E244D)),
  violeta(Color(0xFF5E35B1)),
  marrom(Color(0xFF6D4C41));

  const CorTag(this.cor);

  final Color cor;

  /// Cores na ordem da paleta: por tom (do vermelho ao rosa) e, no fim, marrom e cinza.
  static const paleta = [
    vermelho,
    vinho,
    laranja,
    ambar,
    amarelo,
    lima,
    verde,
    turquesa,
    ciano,
    azul,
    anil,
    violeta,
    roxo,
    rosa,
    marrom,
    cinza,
  ];

  /// Cor pelo nome gravado; [cinza] se ausente ou desconhecido (tags gravadas antes de terem cor).
  static CorTag doNome(Object? nome) => values.where((c) => c.name == nome).firstOrNull ?? cinza;
}

/// Tag que o usuário cria para organizar as anotações da leitura.
typedef TagLeitura = ({String id, String nome, CorTag cor});

/// Anotação presa a um trecho do capítulo: do caractere [inicio] do versículo [versIdInicio] ao [fim] (exclusivo)
/// do versículo [versIdFim]. [tags] guarda os ids das [TagLeitura].
typedef AnotacaoTrecho = ({
  String id,
  int versIdInicio,
  int inicio,
  int versIdFim,
  int fim,
  String texto,
  List<String> tags,
  DateTime atualizadaEm,
});

/// Onde ficam as anotações da leitura (por versão e capítulo, como o marca-texto) e as tags.
///
/// Ficam no aparelho (não sincronizam entre aparelhos) e valem com ou sem login.
abstract interface class AnotacaoArmazenamento {
  /// Anotações do capítulo; lista vazia se não houver.
  Future<List<AnotacaoTrecho>> doCapitulo(int versaId, int livrId, int capiNumero);

  /// Substitui as anotações do capítulo (lista vazia apaga).
  Future<void> salvarCapitulo(int versaId, int livrId, int capiNumero, List<AnotacaoTrecho> anotacoes);

  /// Tags criadas pelo usuário.
  Future<List<TagLeitura>> tags();

  /// Substitui as tags.
  Future<void> salvarTags(List<TagLeitura> tags);
}

/// [AnotacaoArmazenamento] em secure storage: uma chave por capítulo e uma para as tags, em JSON.
class AnotacaoArmazenamentoLocal implements AnotacaoArmazenamento {
  AnotacaoArmazenamentoLocal({BBSecureStorage? storage}) : _storage = storage ?? BBSecureStorage();

  final BBSecureStorage _storage;

  static String chave(int versaId, int livrId, int capiNumero) => '$kReadingNotes:$versaId:$livrId:$capiNumero';

  @override
  Future<List<AnotacaoTrecho>> doCapitulo(int versaId, int livrId, int capiNumero) async =>
      decodificar(await _storage.readSecureData(chave(versaId, livrId, capiNumero)));

  @override
  Future<void> salvarCapitulo(int versaId, int livrId, int capiNumero, List<AnotacaoTrecho> anotacoes) async {
    final key = chave(versaId, livrId, capiNumero);
    if (anotacoes.isEmpty) return _storage.deleteSecureDataByKey(key);
    return _storage.writeSecureData(SecureStorageModel(key, codificar(anotacoes)));
  }

  @override
  Future<List<TagLeitura>> tags() async => decodificarTags(await _storage.readSecureData(kReadingTags));

  @override
  Future<void> salvarTags(List<TagLeitura> tags) async {
    if (tags.isEmpty) return _storage.deleteSecureDataByKey(kReadingTags);
    return _storage.writeSecureData(SecureStorageModel(kReadingTags, codificarTags(tags)));
  }

  static String codificar(List<AnotacaoTrecho> anotacoes) => jsonEncode([
    for (final a in anotacoes)
      {
        'id': a.id,
        'vi': a.versIdInicio,
        'i': a.inicio,
        'vf': a.versIdFim,
        'f': a.fim,
        't': a.texto,
        'g': a.tags,
        'd': a.atualizadaEm.toIso8601String(),
      },
  ]);

  /// Anotações do JSON gravado; ausente, inválido ou com itens inválidos vira lista vazia (ou sem esses itens).
  static List<AnotacaoTrecho> decodificar(String? json) {
    final lista = _lista(json);
    return [
      for (final item in lista)
        if (item case {
          'id': final String id,
          'vi': final int vi,
          'i': final int i,
          'vf': final int vf,
          'f': final int f,
          't': final String t,
          'g': final List<dynamic> g,
          'd': final String d,
        })
          if (DateTime.tryParse(d) case final data?)
            (
              id: id,
              versIdInicio: vi,
              inicio: i,
              versIdFim: vf,
              fim: f,
              texto: t,
              tags: g.whereType<String>().toList(),
              atualizadaEm: data,
            ),
    ];
  }

  static String codificarTags(List<TagLeitura> tags) => jsonEncode([
    for (final t in tags) {'id': t.id, 'n': t.nome, 'c': t.cor.name},
  ]);

  static List<TagLeitura> decodificarTags(String? json) => [
    for (final item in _lista(json))
      if (item case {'id': final String id, 'n': final String nome})
        (id: id, nome: nome, cor: CorTag.doNome(item['c'])),
  ];

  static List<dynamic> _lista(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final lista = jsonDecode(json);
      return lista is List ? lista : const [];
    } on FormatException {
      return const [];
    }
  }
}
