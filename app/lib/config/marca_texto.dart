import 'dart:convert';

import 'package:commons/commons.dart';
import 'package:components/components.dart' show HighlightColor;

/// Trecho pintado com o marca-texto num versículo: de [inicio] a [fim] (exclusivo) no texto do versículo.
typedef MarcaTexto = ({int versId, int inicio, int fim, HighlightColor cor});

/// Onde ficam as marcações do marca-texto da leitura, por versão e capítulo (o texto, e as posições, mudam de
/// uma versão para outra).
///
/// Ficam no aparelho (não sincronizam entre aparelhos) e valem com ou sem login.
abstract interface class MarcaTextoArmazenamento {
  /// Marcações do capítulo; lista vazia se não houver.
  Future<List<MarcaTexto>> doCapitulo(int versaId, int livrId, int capiNumero);

  /// Substitui as marcações do capítulo (lista vazia apaga).
  Future<void> salvarCapitulo(int versaId, int livrId, int capiNumero, List<MarcaTexto> marcas);
}

/// [MarcaTextoArmazenamento] em secure storage: uma chave por capítulo com as marcações em JSON.
class MarcaTextoArmazenamentoLocal implements MarcaTextoArmazenamento {
  MarcaTextoArmazenamentoLocal({BBSecureStorage? storage}) : _storage = storage ?? BBSecureStorage();

  final BBSecureStorage _storage;

  static String chave(int versaId, int livrId, int capiNumero) => '$kReadingHighlights:$versaId:$livrId:$capiNumero';

  @override
  Future<List<MarcaTexto>> doCapitulo(int versaId, int livrId, int capiNumero) async =>
      decodificar(await _storage.readSecureData(chave(versaId, livrId, capiNumero)));

  @override
  Future<void> salvarCapitulo(int versaId, int livrId, int capiNumero, List<MarcaTexto> marcas) async {
    final key = chave(versaId, livrId, capiNumero);
    if (marcas.isEmpty) return _storage.deleteSecureDataByKey(key);
    return _storage.writeSecureData(SecureStorageModel(key, codificar(marcas)));
  }

  static String codificar(List<MarcaTexto> marcas) => jsonEncode([
    for (final m in marcas) {'v': m.versId, 'i': m.inicio, 'f': m.fim, 'c': m.cor.name},
  ]);

  /// Marcações do JSON gravado; ausente, inválido ou com itens inválidos vira lista vazia (ou sem esses itens).
  static List<MarcaTexto> decodificar(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final lista = jsonDecode(json);
      if (lista is! List) return const [];
      return [
        for (final item in lista)
          if (item case {'v': final int v, 'i': final int i, 'f': final int f, 'c': final String c}
              when f > i && HighlightColor.values.any((cor) => cor.name == c))
            (versId: v, inicio: i, fim: f, cor: HighlightColor.values.byName(c)),
      ];
    } on FormatException {
      return const [];
    }
  }
}
