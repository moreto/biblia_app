import 'package:flutter/material.dart';

import '../../../../../data/model/biblia/capitulo_lido_model.dart';

/// Número de um capítulo no índice da leitura, clicável, com o estado de leitura:
/// preenchido (lido por completo), contornado na cor primária (parcialmente lido) ou neutro (não lido).
class CapituloChip extends StatelessWidget {
  const CapituloChip({super.key, required this.numero, required this.lido, required this.onTap});

  final int numero;

  /// Progresso do capítulo; nulo se nenhum versículo foi lido.
  final CapituloLidoModel? lido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completo = lido?.completo ?? false;
    final parcial = lido != null && !completo;

    return Material(
      color: completo ? scheme.primary : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: parcial ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Text(
              '$numero',
              style: TextStyle(
                color: completo ? scheme.onPrimary : (parcial ? scheme.primary : scheme.onSurfaceVariant),
                fontWeight: lido == null ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
