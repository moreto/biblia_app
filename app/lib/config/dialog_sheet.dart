import 'package:components/components.dart' as componentes;
import 'package:flutter/material.dart';

/// Abre telas e formulários no componente `DialogBottomSheet` (no lugar de `showDialog`/`AlertDialog`).
///
/// - Título: [titulo] (texto) ou [cabecalho] (widget livre), ao lado do X do componente.
/// - [conteudo] ganha margem lateral/inferior, tema claro com a cor primária do app ([tema]: o componente tem
///   fundo claro fixo, então o conteúdo fica legível também no modo escuro) e um `Material` transparente (o
///   componente pinta o fundo num `Container`, e `ListTile`/`InkWell` precisam de um `Material` para o toque).
/// - Retorna o valor passado ao `Navigator.pop`, ou `null` ao fechar pelo X/arrastar.
/// - [isDismissible] falso (formulários) impede fechar tocando fora/arrastando; o X continua fechando.
abstract final class DialogSheet {
  /// Tema claro com a cor primária do app, para o fundo claro fixo do `DialogBottomSheet`.
  static ThemeData tema(BuildContext context) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Theme.of(context).colorScheme.primary),
    useMaterial3: true,
  );

  static Future<T?> show<T>(
    BuildContext context, {
    String? titulo,
    Widget? cabecalho,
    required Widget conteudo,
    bool isDismissible = true,
  }) {
    final tema = DialogSheet.tema(context);
    return componentes.DialogBottomSheet(
      componentes.Dialog(
        isDismissible: isDismissible,
        bottomSheetTitle: Theme(
          data: tema,
          child:
              cabecalho ??
              Builder(
                builder: (context) => Text(
                  titulo ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
        ),
        widget: Theme(
          data: tema,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: conteudo),
          ),
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
