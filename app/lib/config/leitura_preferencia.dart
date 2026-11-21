import 'package:components/components.dart' show HighlightColor;
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

/// Orientação da tela na leitura.
enum OrientacaoLeitura {
  /// Segue o aparelho (gira com ele).
  automatica,

  /// Fica sempre em pé.
  retrato,

  /// Fica sempre deitada.
  paisagem,
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

  /// Orientação da tela na leitura.
  OrientacaoLeitura get orientacao;

  void setOrientacao(OrientacaoLeitura orientacao);

  /// Tema só da tela de leitura: [TemaApp.sistema] usa o mesmo do app; claro, creme ou escuro valem só ali.
  TemaApp get temaLeitura;

  void setTemaLeitura(TemaApp tema);

  /// Brilho da tela só na leitura (0 a 1); nulo usa o do sistema.
  double? get brilhoLeitura;

  void setBrilhoLeitura(double? brilho);

  /// Cor do marca-texto: "Marcar texto" no sheet do trecho usa ela (a escolha da cor fica só nas configurações).
  HighlightColor get corMarcaTexto;

  void setCorMarcaTexto(HighlightColor cor);
}
