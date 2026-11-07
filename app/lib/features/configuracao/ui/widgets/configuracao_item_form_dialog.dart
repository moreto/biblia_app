import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../../data/model/configuracao/configuracao_model.dart';
import 'configuracao_dialog_layout.dart';

/// Formulário de inclusão/alteração de item de configuração.
/// Retorna o [ConfiguracaoItemModel] preenchido ou `null` quando cancelado.
class ConfiguracaoItemFormDialog extends StatefulWidget {
  const ConfiguracaoItemFormDialog({super.key, required this.configuracoes, required this.confId, this.item});

  final List<ConfiguracaoModel> configuracoes;
  final int confId;
  final ConfiguracaoItemModel? item;

  static Future<ConfiguracaoItemModel?> show(
    BuildContext context, {
    required List<ConfiguracaoModel> configuracoes,
    required int confId,
    ConfiguracaoItemModel? item,
  }) => showDialog<ConfiguracaoItemModel>(
    context: context,
    builder: (context) => ConfiguracaoItemFormDialog(configuracoes: configuracoes, confId: confId, item: item),
  );

  @override
  State<ConfiguracaoItemFormDialog> createState() => _ConfiguracaoItemFormDialogState();
}

class _ConfiguracaoItemFormDialogState extends State<ConfiguracaoItemFormDialog> {
  late int _confId = widget.item?.confId ?? widget.confId;
  late final TextEditingController _campoController = TextEditingController(text: widget.item?.citeCampo);
  late final TextEditingController _chaveController = TextEditingController(text: widget.item?.citeChave?.toString());
  late final TextEditingController _valorController = TextEditingController(text: widget.item?.citeValor);
  late final TextEditingController _sequenciaController = TextEditingController(
    text: widget.item?.citeSequencia?.toString(),
  );
  late bool _ativo = widget.item?.citeAtivo ?? true;

  @override
  void dispose() {
    _campoController.dispose();
    _chaveController.dispose();
    _valorController.dispose();
    _sequenciaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    Navigator.of(context).pop(
      ConfiguracaoItemModel(
        citeId: widget.item?.citeId,
        confId: _confId,
        citeCampo: _campoController.text,
        citeChave: int.tryParse(_chaveController.text),
        citeValor: _valorController.text,
        citeSequencia: int.tryParse(_sequenciaController.text),
        citeAtivo: _ativo,
        createdAt: widget.item?.createdAt,
        updatedAt: widget.item?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isNovo = widget.item?.citeId == null;

    return ConfiguracaoDialogLayout(
      title: strings.translate(isNovo ? 'novoItemConfiguracao' : 'editarItemConfiguracao'),
      onSave: _confirmar,
      fields: [
        if (!isNovo) Text('${strings.translate('codigo')}: ${widget.item!.citeId}'),
        DropdownButtonFormField<int>(
          initialValue: _confId,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.translate('configuracao')),
          items: widget.configuracoes
              .where((configuracao) => configuracao.confId != null)
              .map(
                (configuracao) => DropdownMenuItem<int>(
                  value: configuracao.confId,
                  child: Text(configuracao.confNome, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) setState(() => _confId = value);
          },
        ),
        TextField(
          controller: _campoController,
          autofocus: isNovo,
          maxLength: 60,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: strings.translate('campo')),
        ),
        // chave e sequência são numéricos curtos: lado a lado
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chaveController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.translate('chave')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _sequenciaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.translate('sequencia')),
              ),
            ),
          ],
        ),
        TextField(
          controller: _valorController,
          maxLength: 128,
          decoration: InputDecoration(labelText: strings.translate('valor')),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.translate('ativo')),
          value: _ativo,
          onChanged: (value) => setState(() => _ativo = value),
        ),
      ],
    );
  }
}
