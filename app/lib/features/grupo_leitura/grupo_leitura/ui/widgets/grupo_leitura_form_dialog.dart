import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/leitura/leitura_model.dart';
import '../../../../admin/configuracao/ui/widgets/configuracao_dialog_layout.dart';
import '../grupo_leitura_view.dart';

/// Formulário de inclusão/alteração de grupo de leitura: nome e descrição.
///
/// Ao salvar, [validar] (regra do use case, via viewmodel) devolve a chave do problema, mostrada no formulário; sem
/// problema, retorna o [LeituraModel] preenchido. `null` quando cancelado.
class GrupoLeituraFormDialog extends StatefulWidget {
  const GrupoLeituraFormDialog({
    super.key,
    required this.validar,
    required this.nomeMax,
    required this.descricaoMax,
    this.grupo,
  });

  final String? Function(LeituraModel) validar;
  final int nomeMax;
  final int descricaoMax;

  /// Grupo em alteração; nulo na inclusão.
  final LeituraModel? grupo;

  static Future<LeituraModel?> show(
    BuildContext context, {
    required String? Function(LeituraModel) validar,
    required int nomeMax,
    required int descricaoMax,
    LeituraModel? grupo,
  }) => ConfiguracaoDialogLayout.show<LeituraModel>(
    context,
    titulo: AppLocalizations.of(context).translate(grupo?.leitId == null ? 'novoGrupoLeitura' : 'editarGrupoLeitura'),
    form: GrupoLeituraFormDialog(validar: validar, nomeMax: nomeMax, descricaoMax: descricaoMax, grupo: grupo),
  );

  @override
  State<GrupoLeituraFormDialog> createState() => _GrupoLeituraFormDialogState();
}

class _GrupoLeituraFormDialogState extends State<GrupoLeituraFormDialog> {
  late final _nome = TextEditingController(text: widget.grupo?.leitNome);
  late final _descricao = TextEditingController(text: widget.grupo?.leitDescricao);
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  void _confirmar() {
    final grupo = LeituraModel(
      leitId: widget.grupo?.leitId,
      leitNome: _nome.text,
      leitDescricao: _descricao.text,
      usuaId: widget.grupo?.usuaId,
      leitDono: widget.grupo?.leitDono ?? true,
    );
    final erro = widget.validar(grupo);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(grupo);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final novo = widget.grupo?.leitId == null;
    final erro = _erro;

    return ConfiguracaoDialogLayout(
      onSave: _confirmar,
      fields: [
        if (!novo) Text('${strings.translate('codigo')}: ${widget.grupo!.leitId}'),
        TextField(
          controller: _nome,
          autofocus: novo,
          maxLength: widget.nomeMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: strings.translate('nome'),
            prefixIcon: GrupoLeituraView.icone(GrupoLeituraView.iconeGrupo, Icons.menu_book_outlined),
          ),
        ),
        TextField(
          controller: _descricao,
          maxLength: widget.descricaoMax,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.translate('descricao'),
            prefixIcon: GrupoLeituraView.icone(GrupoLeituraView.iconeDescricao, Icons.notes_outlined),
          ),
        ),
        if (erro != null) Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
