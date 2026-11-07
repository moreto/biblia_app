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

  static const AppPalette light = AppPalette(
    primary: brandNavy,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD9E2F2),
    onPrimaryContainer: brandNavy,
    secondary: Color(0xFF8A5A00),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFCF6),
    onSurface: Color(0xFF1C1B18),
    onSurfaceVariant: Color(0xFF5B5446),
    surfaceContainerLow: Color(0xFFFBF5EA),
    surfaceContainer: Color(0xFFF5EEE0),
    surfaceContainerHigh: Color(0xFFEFE7D6),
    outline: Color(0xFF8C8475),
    outlineVariant: Color(0xFFDDD4C3),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    verseNumber: Color(0xFF8A5A00),
    wordsOfJesus: Color(0xFFA4262C),
    sectionTitle: brandNavy,
    highlightYellow: Color(0xFFFFE89A),
    highlightGreen: Color(0xFFCDEBC4),
    highlightBlue: Color(0xFFC9DDF5),
    highlightPink: Color(0xFFF6CFDC),
  );

  static const AppPalette dark = AppPalette(
    primary: brandGold,
    onPrimary: Color(0xFF2A1C00),
    primaryContainer: Color(0xFF1C2E4D),
    onPrimaryContainer: Color(0xFFDCE6F7),
    secondary: Color(0xFFF2C46E),
    onSecondary: Color(0xFF2A1C00),
    surface: Color(0xFF0B1424),
    onSurface: Color(0xFFE9E4DA),
    onSurfaceVariant: Color(0xFFB9B2A4),
    surfaceContainerLow: Color(0xFF101B2F),
    surfaceContainer: Color(0xFF142139),
    surfaceContainerHigh: Color(0xFF1A2843),
    outline: Color(0xFF8A8577),
    outlineVariant: Color(0xFF2E3A52),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    verseNumber: Color(0xFFE3A93B),
    wordsOfJesus: Color(0xFFFF8A80),
    sectionTitle: Color(0xFFF2C46E),
    highlightYellow: Color(0xFF5C4B12),
    highlightGreen: Color(0xFF2C4A2A),
    highlightBlue: Color(0xFF243E61),
    highlightPink: Color(0xFF5A2A3C),
  );
}
