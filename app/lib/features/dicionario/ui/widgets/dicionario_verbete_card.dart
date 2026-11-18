import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/dicionario/dicionario_verbete_model.dart';
import '../../use_case/dicionario_usecase.dart';
import '../dicionario_view.dart';

/// Card de um verbete do dicionário: palavra com o homônimo sobrescrito, pronúncia, etimologia e as acepções
/// numeradas (classe, rótulos de uso, definição com itálico e remissões "Veja também").
///
/// Usado na tela "Dicionário" e no sheet da palavra da leitura. [onRemissao] consulta o termo de uma remissão
/// navegável; nulo deixa as remissões só para leitura.
class DicionarioVerbeteCard extends StatelessWidget {
  const DicionarioVerbeteCard({
    super.key,
    required this.verbete,
    this.onRemissao,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final DicionarioVerbeteModel verbete;
  final ValueChanged<String>? onRemissao;
  final EdgeInsetsGeometry margin;

  /// Texto com os trechos em itálico do original.
  TextSpan _texto(String texto, {TextStyle? style}) => TextSpan(
    style: style,
    children: [
      for (final t in DicionarioUseCase.trechos(texto))
        TextSpan(
          text: t.texto,
          style: t.italico ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final acepcoes = DicionarioUseCase.acepcoes(verbete);

    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  DicionarioUseCase.titulo(verbete.dverPalavra, verbete.dverHomonimo),
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
                ),
                if (verbete.dverPronuncia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('${strings.translate('pronuncia')}: ${verbete.dverPronuncia}', style: secundario),
                  ),
              ],
            ),
            if (verbete.dverEtimologia != null) ...[
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${strings.translate('etimologia')}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _texto(verbete.dverEtimologia!),
                  ],
                ),
                style: secundario,
              ),
            ],
            const Divider(height: 24),
            for (final (index, acepcao) in acepcoes.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              _acepcao(context, acepcao, numerar: acepcoes.length > 1, strings: strings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _acepcao(
    BuildContext context,
    DicionarioAcepcaoModel acepcao, {
    required bool numerar,
    required AppLocalizations strings,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final usos = DicionarioUseCase.usos(acepcao);
    final remissoes = DicionarioUseCase.remissoes(acepcao);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (numerar)
          SizedBox(
            width: 28,
            child: Text(
              '${acepcao.daceSeq}.',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (acepcao.daceClasse != null || usos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (acepcao.daceClasse != null)
                        Text(
                          acepcao.daceClasse!,
                          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: scheme.primary),
                        ),
                      for (final uso in usos)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(uso, style: textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer)),
                        ),
                    ],
                  ),
                ),
              Text.rich(_texto(acepcao.daceDefinicao), style: textTheme.bodyLarge),
              if (remissoes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${strings.translate('vejaTambem')}:', style: textTheme.bodySmall),
                      for (final r in remissoes)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: DicionarioView.icone(DicionarioView.iconeRemissao, Icons.link, size: 16),
                          label: Text(r.termo),
                          onPressed: r.navegavel && onRemissao != null ? () => onRemissao!(r.termo) : null,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
