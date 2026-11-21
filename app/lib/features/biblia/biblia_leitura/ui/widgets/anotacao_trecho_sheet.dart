import 'package:app/config/anotacao_leitura.dart';
import 'package:app/config/dialog_sheet.dart';
import 'package:app/config/ditado_sistema.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Conteúdo do sheet da anotação de um trecho: o texto, digitado ou ditado (o microfone do campo abre o ditado do
/// sistema, [DitadoSistema]; sem ele, o do teclado). As tags ficam no trecho, no sheet dele.
///
/// "Salvar" chama [onSalvar]; com [anotacao] (edição), "Excluir" chama [onExcluir].
class AnotacaoTrechoSheet extends StatefulWidget {
  const AnotacaoTrechoSheet({super.key, required this.ditado, required this.onSalvar, this.anotacao, this.onExcluir});

  /// Atalho do microfone no campo (tela de ditado do sistema); sem ela, vale o microfone do teclado.
  final DitadoSistema ditado;

  final AnotacaoTrecho? anotacao;
  final void Function(String texto) onSalvar;
  final VoidCallback? onExcluir;

  static const tamanhoMaximo = 2000;

  /// Idioma do ditado.
  static const idiomaDitado = 'pt-BR';

  @override
  State<AnotacaoTrechoSheet> createState() => _AnotacaoTrechoSheetState();
}

class _AnotacaoTrechoSheetState extends State<AnotacaoTrechoSheet> {
  late final _texto = TextEditingController(text: widget.anotacao?.texto ?? '');

  bool _ditadoDisponivel = false;
  bool _ditando = false;

  @override
  void initState() {
    super.initState();
    widget.ditado.disponivel().then((disponivel) {
      if (mounted) setState(() => _ditadoDisponivel = disponivel);
    });
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  /// Microfone: abre o ditado do sistema e põe o que foi falado no fim do texto.
  Future<void> _ditar() async {
    if (_ditando) return;
    setState(() => _ditando = true);
    final falado = await widget.ditado.ditar(
      idioma: AnotacaoTrechoSheet.idiomaDitado,
      dica: AppLocalizations.of(context).translate('faleAnotacao'),
    );
    if (!mounted) return;
    setState(() => _ditando = false);
    final texto = falado?.trim() ?? '';
    if (texto.isEmpty) return;
    final antes = _texto.text.trimRight();
    var novo = antes.isEmpty ? texto : '$antes $texto';
    if (novo.length > AnotacaoTrechoSheet.tamanhoMaximo) novo = novo.substring(0, AnotacaoTrechoSheet.tamanhoMaximo);
    _texto.value = TextEditingValue(
      text: novo,
      selection: TextSelection.collapsed(offset: novo.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('textoAnotacao'),
            controller: _texto,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: AnotacaoTrechoSheet.tamanhoMaximo,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: strings.translate('anotacao'),
              // Sem o atalho do microfone, o do próprio teclado.
              helperText: _ditadoDisponivel ? null : strings.translate('dicaDitadoTeclado'),
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: _ditadoDisponivel
                  ? IconButton(
                      tooltip: strings.translate('ditar'),
                      onPressed: _ditando ? null : _ditar,
                      icon: const Icon(Icons.mic_none),
                    )
                  : null,
            ),
          ),
          DialogSheet.acoes([
            if (widget.onExcluir case final excluir?)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  excluir();
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.translate('excluir')),
              )
            else
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('cancelar'))),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSalvar(_texto.text);
              },
              icon: const Icon(Icons.check),
              label: Text(strings.translate('salvar')),
            ),
          ]),
        ],
      ),
    );
  }
}
