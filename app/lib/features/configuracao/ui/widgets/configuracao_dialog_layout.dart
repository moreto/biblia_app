import 'dart:math' as math;

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Estrutura comum dos diálogos de cadastro: largura responsiva, campos espaçados
/// (evita que o rótulo flutuante sobreponha o campo anterior) e ações cancelar/salvar.
class ConfiguracaoDialogLayout extends StatelessWidget {
  const ConfiguracaoDialogLayout({super.key, required this.title, required this.fields, required this.onSave});

  static const double _maxWidth = 480;
  static const double _fieldSpacing = 16;

  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = math.min(_maxWidth, screenWidth - 32);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          // espaço no topo para o rótulo flutuante do primeiro campo
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: _fieldSpacing), fields[i]],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancelar'))),
        FilledButton(onPressed: onSave, child: Text(strings.translate('salvar'))),
      ],
    );
  }
}
