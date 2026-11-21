import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Conteúdo do sheet "Compartilhar" de um trecho: o trecho com a referência e uma mensagem opcional, digitada ou
/// ditada (pelo microfone do teclado). "Compartilhar" fecha o sheet e chama [onCompartilhar] com a mensagem.
class CompartilharTrechoSheet extends StatefulWidget {
  const CompartilharTrechoSheet({
    super.key,
    required this.texto,
    required this.referencia,
    required this.onCompartilhar,
  });

  final String texto;
  final String referencia;
  final void Function(String mensagem) onCompartilhar;

  @override
  State<CompartilharTrechoSheet> createState() => _CompartilharTrechoSheetState();
}

class _CompartilharTrechoSheetState extends State<CompartilharTrechoSheet> {
  final _mensagem = TextEditingController();

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('mensagemCompartilhar'),
          controller: _mensagem,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.translate('mensagemOpcional'),
            // Para falar em vez de digitar, o microfone do próprio teclado (ditado do sistema).
            helperText: strings.translate('dicaDitadoTeclado'),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.2),
          child: SingleChildScrollView(
            child: Text(
              '"${widget.texto}" (${widget.referencia})',
              style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DialogSheet.acoes([
          OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancelar'))),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCompartilhar(_mensagem.text);
            },
            icon: const Icon(Icons.share_outlined),
            label: Text(strings.translate('compartilhar')),
          ),
        ]),
      ],
    );
  }
}
