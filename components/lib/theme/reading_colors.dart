import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores de destaque que o usuário pode aplicar num versículo.
enum HighlightColor { amarelo, verde, azul, rosa }

/// Tokens de cor da leitura, diferentes em light e dark.
@immutable
class ReadingColors extends ThemeExtension<ReadingColors> {
  const ReadingColors({
    required this.verseNumber,
    required this.wordsOfJesus,
    required this.sectionTitle,
    required this.highlightYellow,
    required this.highlightGreen,
    required this.highlightBlue,
    required this.highlightPink,
  });

  factory ReadingColors.fromPalette(AppPalette p) => ReadingColors(
    verseNumber: p.verseNumber,
    wordsOfJesus: p.wordsOfJesus,
    sectionTitle: p.sectionTitle,
    highlightYellow: p.highlightYellow,
    highlightGreen: p.highlightGreen,
    highlightBlue: p.highlightBlue,
    highlightPink: p.highlightPink,
  );

  final Color verseNumber;
  final Color wordsOfJesus;
  final Color sectionTitle;
  final Color highlightYellow;
  final Color highlightGreen;
  final Color highlightBlue;
  final Color highlightPink;

  Color highlight(HighlightColor color) => switch (color) {
    HighlightColor.amarelo => highlightYellow,
    HighlightColor.verde => highlightGreen,
    HighlightColor.azul => highlightBlue,
    HighlightColor.rosa => highlightPink,
  };

  static ReadingColors of(BuildContext context) =>
      Theme.of(context).extension<ReadingColors>()!;

  @override
  ReadingColors copyWith({
    Color? verseNumber,
    Color? wordsOfJesus,
    Color? sectionTitle,
    Color? highlightYellow,
    Color? highlightGreen,
    Color? highlightBlue,
    Color? highlightPink,
  }) {
    return ReadingColors(
      verseNumber: verseNumber ?? this.verseNumber,
      wordsOfJesus: wordsOfJesus ?? this.wordsOfJesus,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      highlightYellow: highlightYellow ?? this.highlightYellow,
      highlightGreen: highlightGreen ?? this.highlightGreen,
      highlightBlue: highlightBlue ?? this.highlightBlue,
      highlightPink: highlightPink ?? this.highlightPink,
    );
  }

  @override
  ReadingColors lerp(ReadingColors? other, double t) {
    if (other == null) return this;
    return ReadingColors(
      verseNumber: Color.lerp(verseNumber, other.verseNumber, t)!,
      wordsOfJesus: Color.lerp(wordsOfJesus, other.wordsOfJesus, t)!,
      sectionTitle: Color.lerp(sectionTitle, other.sectionTitle, t)!,
      highlightYellow: Color.lerp(highlightYellow, other.highlightYellow, t)!,
      highlightGreen: Color.lerp(highlightGreen, other.highlightGreen, t)!,
      highlightBlue: Color.lerp(highlightBlue, other.highlightBlue, t)!,
      highlightPink: Color.lerp(highlightPink, other.highlightPink, t)!,
    );
  }
}
