/// Capítulo aberto na leitura: versão, livro e número.
typedef UltimoCapitulo = ({int versaId, int livrId, int capiNumero});

/// Último capítulo aberto na leitura, guardado no aparelho entre as aberturas do app (com ou sem login).
///
/// Implementada por `AppConfig` (secure storage); os use cases dependem só desta interface, o que permite
/// testá-los sem o storage do dispositivo.
abstract interface class UltimoCapituloPreferencia {
  /// Último capítulo aberto; nulo se nenhum capítulo foi aberto ainda.
  UltimoCapitulo? get ultimoCapitulo;

  /// Grava o capítulo aberto.
  void setUltimoCapitulo(UltimoCapitulo capitulo);
}
