import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import 'app_config.dart';

/// Botão para as `actions` das AppBars que alterna entre tema claro e escuro.
///
/// Considera o brilho efetivo da tela (inclusive quando o modo é `system`)
/// e grava o modo oposto em [AppConfig]. O ícone e o tooltip indicam o modo
/// que será aplicado ao tocar.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: strings.translate(isDark ? 'claro' : 'escuro'),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => context.read<AppConfig>().setMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
