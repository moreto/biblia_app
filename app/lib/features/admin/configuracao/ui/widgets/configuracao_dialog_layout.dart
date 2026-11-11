import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Estrutura comum dos formulários de cadastro abertos no `DialogBottomSheet` ([show]): campos espaçados (evita
/// que o rótulo flutuante sobreponha o campo anterior) e ações cancelar/salvar.
class ConfiguracaoDialogLayout extends StatelessWidget {
  const ConfiguracaoDialogLayout({super.key, required this.fields, required this.onSave});

  static const double _fieldSpacing = 16;

  final List<Widget> fields;
  final VoidCallback onSave;

  /// Abre o formulário [form] (que usa este layout) com o [titulo]; não fecha tocando fora, para não perder o que
  /// foi digitado. Retorna o valor de `Navigator.pop` (o registro salvo) ou `null` quando cancelado.
  static Future<T?> show<T>(BuildContext context, {required String titulo, required Widget form}) =>
      DialogSheet.show<T>(context, titulo: titulo, conteudo: form, isDismissible: false);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // espaço no topo para o rótulo flutuante do primeiro campo
        const SizedBox(height: 8),
        for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: _fieldSpacing), fields[i]],
        DialogSheet.acoes([
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancelar'))),
          FilledButton(onPressed: onSave, child: Text(strings.translate('salvar'))),
        ]),
      ],
    );
  }
}
