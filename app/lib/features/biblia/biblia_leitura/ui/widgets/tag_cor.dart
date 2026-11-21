import 'package:app/config/anotacao_leitura.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Aparência das tags pela [CorTag]: bolinha cheia e fundo bem claro do mesmo tom.
abstract final class TagCor {
  /// Fundo do chip da tag (selecionada, no filtro, um pouco mais forte).
  static Color fundo(CorTag cor, {bool selecionada = false}) => cor.cor.withValues(alpha: selecionada ? 0.32 : 0.18);

  /// Borda do chip da tag.
  static BorderSide borda(CorTag cor) => BorderSide(color: cor.cor.withValues(alpha: 0.6));

  static Widget bolinha(CorTag cor, {double tamanho = 14}) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(color: cor.cor, shape: BoxShape.circle),
  );

  /// Paleta para escolher a cor; [atual] aparece marcada.
  static Widget seletor(BuildContext context, {required CorTag atual, required ValueChanged<CorTag> onEscolher}) {
    final strings = AppLocalizations.of(context);
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        for (final cor in CorTag.paleta)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: strings.translate('corTag_${cor.name}'),
            onPressed: () => onEscolher(cor),
            icon: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: cor.cor, shape: BoxShape.circle),
              child: cor == atual ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
            ),
          ),
      ],
    );
  }
}
