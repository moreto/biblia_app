import 'package:flutter/material.dart';

/// Escala tipográfica do app.
///
/// A UI usa a fonte do sistema (Roboto no Android, SF no iOS). O texto
/// bíblico usa uma fonte serifada do sistema, via [TextStyleX.reading].
abstract final class AppTypography {
  /// Famílias serifadas tentadas em ordem (iOS, Android, genérica).
  static const List<String> readingFallback = [
    'Georgia',
    'Noto Serif',
    'serif',
  ];

  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 18, height: 1.7, color: onSurface),
      bodyMedium: TextStyle(fontSize: 15, height: 1.5, color: onSurface),
      bodySmall: TextStyle(fontSize: 13, height: 1.4, color: onSurfaceVariant),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: onSurfaceVariant,
      ),
    );
  }
}

extension TextStyleX on TextStyle {
  /// Estilo do texto bíblico: serifado e com entrelinha confortável.
  TextStyle get reading => copyWith(
    fontFamily: AppTypography.readingFallback.first,
    fontFamilyFallback: AppTypography.readingFallback,
    height: 1.75,
  );

  /// Números com largura fixa (capítulos, versículos).
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
