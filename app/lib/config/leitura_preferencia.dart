import 'package:flutter/material.dart';

/// Tema escolhido pelo usuário. [creme] é um tema claro com papel creme; os demais seguem o `ThemeMode`.
enum TemaApp {
  sistema(ThemeMode.system),
  claro(ThemeMode.light),
  creme(ThemeMode.light),
  escuro(ThemeMode.dark);

  const TemaApp(this.mode);

  /// Modo usado pelo `MaterialApp`.
  final ThemeMode mode;
}

/// O que fazer com o capítulo que fica para trás ao passar para o próximo.
enum MarcarAoPassar {
  /// Não marca.
  nunca,

  /// Pergunta se marca como lido.
  perguntar,

  /// Marca como lido sem perguntar.
  sempre,
}

/// Preferências do sheet "Opções de leitura": tamanho da fonte do texto bíblico e tema do app.
///
/// Implementada por `AppConfig` (secure storage); os use cases dependem só desta interface, o que permite
/// testá-los sem o storage do dispositivo.
abstract interface class LeituraPreferencia {
  /// Multiplicador do tamanho da fonte dos versículos (1 = tamanho padrão do tema).
  double get escalaFonte;

  /// Grava o multiplicador da fonte.
  void setEscalaFonte(double escala);

  /// Mostrar as setas anterior/próximo na navegação flutuante da leitura.
  bool get mostrarSetas;

  /// Grava se as setas aparecem.
  void setMostrarSetas(bool mostrar);

  /// O que fazer com o capítulo ao passar para o próximo.
  MarcarAoPassar get marcarAoPassar;

  /// Grava o que fazer ao passar a página.
  void setMarcarAoPassar(MarcarAoPassar valor);

  /// Nome da voz escolhida para a narração; nulo usa a melhor voz disponível.
  String? get vozNarracao;

  void setVozNarracao(String? nome);

  /// Velocidade da narração (0,5 = normal); nula usa a padrão.
  double? get velocidadeNarracao;

  void setVelocidadeNarracao(double velocidade);

  /// Narração contínua: ao terminar o capítulo, passa a página e continua lendo o próximo.
  bool get narracaoContinua;

  void setNarracaoContinua(bool continua);

  /// Tema do app: sistema, claro, creme ou escuro.
  TemaApp get tema;

  /// Grava o tema do app.
  void setTema(TemaApp tema);
}
