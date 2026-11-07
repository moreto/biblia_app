import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../data/model/configuracao/configuracao_model.dart';
import 'configuracao_dialog_layout.dart';

/// Formulário de inclusão/alteração de configuração.
/// Retorna o [ConfiguracaoModel] preenchido ou `null` quando cancelado.
class ConfiguracaoFormDialog extends StatefulWidget {
  const ConfiguracaoFormDialog({super.key, this.configuracao});

  final ConfiguracaoModel? configuracao;

  static Future<ConfiguracaoModel?> show(BuildContext context, {ConfiguracaoModel? configuracao}) =>
      showDialog<ConfiguracaoModel>(
        context: context,
        builder: (context) => ConfiguracaoFormDialog(configuracao: configuracao),
      );

  @override
  State<ConfiguracaoFormDialog> createState() => _ConfiguracaoFormDialogState();
}

class _ConfiguracaoFormDialogState extends State<ConfiguracaoFormDialog> {
  late final TextEditingController _nomeController = TextEditingController(text: widget.configuracao?.confNome);
  late final TextEditingController _tipoController = TextEditingController(
    text: widget.configuracao?.confTipo?.toString(),
  );
  late bool _ativo = widget.configuracao?.confAtivo ?? true;

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    Navigator.of(context).pop(
      ConfiguracaoModel(
        confId: widget.configuracao?.confId,
        confNome: _nomeController.text,
        confTipo: int.tryParse(_tipoController.text),
        confAtivo: _ativo,
        createdAt: widget.configuracao?.createdAt,
        updatedAt: widget.configuracao?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isNovo = widget.configuracao?.confId == null;

    return ConfiguracaoDialogLayout(
      title: strings.translate(isNovo ? 'novaConfiguracao' : 'editarConfiguracao'),
      onSave: _confirmar,
      fields: [
        if (!isNovo) Text('${strings.translate('codigo')}: ${widget.configuracao!.confId}'),
        TextField(
          controller: _nomeController,
          autofocus: isNovo,
          maxLength: 60,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: strings.translate('nome')),
        ),
        TextField(
          controller: _tipoController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: strings.translate('tipo')),
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
