import 'package:flutter/material.dart';

/// Valores de cor de um modo (light ou dark).
@immutable
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.verseNumber,
    required this.wordsOfJesus,
    required this.sectionTitle,
    required this.highlightYellow,
    required this.highlightGreen,
    required this.highlightBlue,
    required this.highlightPink,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;

  // Leitura
  final Color verseNumber;
  final Color wordsOfJesus;
  final Color sectionTitle;

  // Destaques (fundo atrás do texto do versículo)
  final Color highlightYellow;
  final Color highlightGreen;
  final Color highlightBlue;
  final Color highlightPink;
}

/// Únicos valores de cor do app. Nenhum widget usa `Color(0x...)` fora daqui.
abstract final class AppColors {
  /// Cores da marca, tiradas do ícone.
  static const Color brandNavy = Color(0xFF0A1A33);
  static const Color brandGold = Color(0xFFE3A93B);
  static const Color brandParchment = Color(0xFFFBF3E0);

  /// Tema claro inspirado no Kindle: papel e-ink neutro, tinta quase preta
  /// e interface em tons de cinza, sem cores de marca competindo com o texto.
  static const AppPalette light = AppPalette(
    primary: Color(0xFF1A1A1A),
    onPrimary: Color(0xFFE8E6E0),
    primaryContainer: Color(0xFFD2D0C9),
    onPrimaryContainer: Color(0xFF1A1A1A),
    secondary: Color(0xFF4A4945),
    onSecondary: Color(0xFFE8E6E0),
    secondaryContainer: Color(0xFFBDBAB1),
    onSecondaryContainer: Color(0xFF1C1C1A),
    surface: Color(0xFFE8E6E0),
    onSurface: Color(0xFF1C1C1A),
    onSurfaceVariant: Color(0xFF55544F),
    surfaceContainerLow: Color(0xFFE1DFD9),
    surfaceContainer: Color(0xFFDAD8D1),
    surfaceContainerHigh: Color(0xFFD2D0C9),
    outline: Color(0xFF84827C),
    outlineVariant: Color(0xFFC6C4BD),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    verseNumber: Color(0xFF6E6D67),
    wordsOfJesus: Color(0xFF8E2B2B),
    sectionTitle: Color(0xFF1C1C1A),
    highlightYellow: Color(0xFFE2D59E),
    highlightGreen: Color(0xFFC8D6C0),
    highlightBlue: Color(0xFFC4CFDC),
    highlightPink: Color(0xFFDCC6CC),
  );

  /// Tema creme: papel creme, tinta marrom-escura, azul-marinho da marca e dourado nos destaques. Mais quente que
  /// o [light], para leituras longas.
  static const AppPalette creme = AppPalette(
    primary: Color(0xFF1B2C4E),
    onPrimary: Color(0xFFFFF8E8),
    primaryContainer: Color(0xFFDCE2EE),
    onPrimaryContainer: Color(0xFF1B2C4E),
    secondary: Color(0xFF7A5210),
    onSecondary: Color(0xFFFFF8E8),
    secondaryContainer: Color(0xFFFFE7A3),
    onSecondaryContainer: Color(0xFF3F2A05),
    surface: Color(0xFFFFF8E8),
    onSurface: Color(0xFF2B2418),
    onSurfaceVariant: Color(0xFF6B5D45),
    surfaceContainerLow: Color(0xFFFBF1DC),
    surfaceContainer: Color(0xFFF6EAD0),
    surfaceContainerHigh: Color(0xFFF1E3C5),
    outline: Color(0xFF9A8B70),
    outlineVariant: Color(0xFFEFDDB9),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    verseNumber: Color(0xFF1B2C4E),
    wordsOfJesus: Color(0xFF8E2B2B),
    sectionTitle: Color(0xFF2B2418),
    highlightYellow: Color(0xFFFFE7A3),
    highlightGreen: Color(0xFFD9E5C8),
    highlightBlue: Color(0xFFD3DDEB),
    highlightPink: Color(0xFFF0D3D6),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFFC2924A),
    onPrimary: Color(0xFF2A1C00),
    primaryContainer: Color(0xFF18263F),
    onPrimaryContainer: Color(0xFFB4BDCC),
    secondary: Color(0xFFCCA762),
    onSecondary: Color(0xFF2A1C00),
    secondaryContainer: Color(0xFF4A3D22),
    onSecondaryContainer: Color(0xFFE0C58E),
    surface: Color(0xFF080F1B),
    onSurface: Color(0xFFBDB8AE),
    onSurfaceVariant: Color(0xFF8F897D),
    surfaceContainerLow: Color(0xFF0D1626),
    surfaceContainer: Color(0xFF111C30),
    surfaceContainerHigh: Color(0xFF16233A),
    outline: Color(0xFF6E6A60),
    outlineVariant: Color(0xFF253047),
    error: Color(0xFFD69C99),
    onError: Color(0xFF601410),
    verseNumber: Color(0xFFA9844A),
    wordsOfJesus: Color(0xFFD27A72),
    sectionTitle: Color(0xFFC29E5C),
    highlightYellow: Color(0xFF473A10),
    highlightGreen: Color(0xFF223A21),
    highlightBlue: Color(0xFF1C304C),
    highlightPink: Color(0xFF46212F),
  );
}
