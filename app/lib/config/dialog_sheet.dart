import 'package:components/components.dart' as componentes;
import 'package:flutter/material.dart';

/// Abre telas e formulários no componente `DialogBottomSheet` (no lugar de `showDialog`/`AlertDialog`).
///
/// - Título: [titulo] (texto) ou [cabecalho] (widget livre), ao lado do X do componente.
/// - O sheet segue o tema do app (claro ou escuro): o componente pinta o fundo com `colorScheme.surface`.
/// - [conteudo] ganha margem lateral/inferior e um `Material` transparente (o componente pinta o fundo num
///   `Container`, e `ListTile`/`InkWell` precisam de um `Material` para o toque).
/// - Retorna o valor passado ao `Navigator.pop`, ou `null` ao fechar pelo X/arrastar.
/// - [isDismissible] falso (formulários) impede fechar tocando fora/arrastando; o X continua fechando.
abstract final class DialogSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    String? titulo,
    Widget? cabecalho,
    required Widget conteudo,
    bool isDismissible = true,
  }) {
    return componentes.DialogBottomSheet(
      componentes.Dialog(
        isDismissible: isDismissible,
        bottomSheetTitle:
            cabecalho ??
            Builder(
              builder: (context) => Text(
                titulo ?? '',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
        widget: Material(
          type: MaterialType.transparency,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: conteudo),
        ),
      ),
    ).showModal<T>(context);
  }

  /// Linha de ações no fim do conteúdo (alinhada à direita), como as `actions` de um `AlertDialog`.
  static Widget acoes(List<Widget> botoes) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: botoes),
  );
}
