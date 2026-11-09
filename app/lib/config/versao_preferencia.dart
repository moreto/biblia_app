/// Versão da Bíblia escolhida pelo usuário, guardada entre as aberturas do app.
///
/// Implementada por `AppConfig` (secure storage); os use cases dependem só desta interface, o que permite
/// testá-los sem o storage do dispositivo.
abstract interface class VersaoPreferencia {
  /// `versaId` salvo; nulo se o usuário ainda não escolheu uma versão.
  int? get versaoId;

  /// Grava a versão escolhida.
  void setVersaoId(int versaId);
}
