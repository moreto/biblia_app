import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../versiculo_reacao/use_case/versiculo_reacao_usecase.dart';

/// Aberto no `DialogBottomSheet` ([show]) ao marcar o versículo como lido: comentário opcional, pré-preenchido com
/// o atual. Retorna o texto digitado (pode ser vazio) em "Salvar" ou `null` em "Cancelar"/X.
class VersiculoComentarioDialog extends StatefulWidget {
  const VersiculoComentarioDialog({super.key, this.comentario});

  final String? comentario;

  static Future<String?> show(BuildContext context, {String? comentario}) => DialogSheet.show<String>(
    context,
    titulo: AppLocalizations.of(context).translate('marcarComoLido'),
    isDismissible: false,
    conteudo: VersiculoComentarioDialog(comentario: comentario),
  );

  @override
  State<VersiculoComentarioDialog> createState() => _VersiculoComentarioDialogState();
}

class _VersiculoComentarioDialogState extends State<VersiculoComentarioDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.comentario);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvar() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: VersiculoReacaoUseCase.comentarioMaximo,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.translate('comentarioOpcional'),
            border: const OutlineInputBorder(),
          ),
        ),
        DialogSheet.acoes([
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancelar'))),
          FilledButton(onPressed: _salvar, child: Text(strings.translate('salvar'))),
        ]),
      ],
    );
  }
}
