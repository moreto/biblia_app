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

  /// Altura dos botões de [acoes], a mesma do `FilledButton` do tema do app.
  static const double alturaAcao = 52;

  /// Linha de ações no fim do conteúdo, como as `actions` de um `AlertDialog`: os [botoes] ficam lado a lado,
  /// dividem a largura em partes iguais e têm a mesma altura ([alturaAcao]). Ponha a ação principal por último
  /// (à direita).
  static Widget acoes(List<Widget> botoes) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Row(
      children: [
        for (var i = 0; i < botoes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: SizedBox(height: alturaAcao, child: botoes[i])),
        ],
      ],
    ),
  );
}
