import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/comunidade/comunidade_denominacao_model.dart';
import '../../../../../data/model/comunidade/comunidade_model.dart';
import '../../../../../data/model/comunidade/comunidade_tipo_model.dart';
import '../../../../admin/configuracao/ui/widgets/configuracao_dialog_layout.dart';
import '../comunidade_view.dart';

/// Formulário de inclusão/alteração de comunidade: nome, tipo e denominação.
///
/// Ao salvar, [validar] (regra do use case, via viewmodel) devolve a chave do problema, mostrada no formulário; sem
/// problema, retorna o [ComunidadeModel] preenchido. `null` quando cancelado.
class ComunidadeFormDialog extends StatefulWidget {
  const ComunidadeFormDialog({
    super.key,
    required this.tipos,
    required this.denominacoes,
    required this.validar,
    required this.nomeMax,
    this.comunidade,
  });

  final List<ComunidadeTipoModel> tipos;
  final List<ComunidadeDenominacaoModel> denominacoes;
  final String? Function(ComunidadeModel) validar;
  final int nomeMax;

  /// Comunidade em alteração; nula na inclusão.
  final ComunidadeModel? comunidade;

  static Future<ComunidadeModel?> show(
    BuildContext context, {
    required List<ComunidadeTipoModel> tipos,
    required List<ComunidadeDenominacaoModel> denominacoes,
    required String? Function(ComunidadeModel) validar,
    required int nomeMax,
    ComunidadeModel? comunidade,
  }) => showDialog<ComunidadeModel>(
    context: context,
    builder: (context) => ComunidadeFormDialog(
      tipos: tipos,
      denominacoes: denominacoes,
      validar: validar,
      nomeMax: nomeMax,
      comunidade: comunidade,
    ),
  );

  @override
  State<ComunidadeFormDialog> createState() => _ComunidadeFormDialogState();
}

class _ComunidadeFormDialogState extends State<ComunidadeFormDialog> {
  late final TextEditingController _nomeController = TextEditingController(text: widget.comunidade?.comuNome);
  late int? _ctipId = _existente(widget.comunidade?.ctipId, widget.tipos.map((t) => t.ctipId));
  late int? _cdenId = _existente(widget.comunidade?.cdenId, widget.denominacoes.map((d) => d.cdenId));
  String? _erro;

  /// O id só vale como seleção inicial se estiver entre as opções (o dropdown exige).
  static int? _existente(int? id, Iterable<int> opcoes) => opcoes.contains(id) ? id : null;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final comunidade = ComunidadeModel(
      comuId: widget.comunidade?.comuId,
      comuNome: _nomeController.text,
      ctipId: _ctipId,
      cdenId: _cdenId,
      usuaId: widget.comunidade?.usuaId,
    );
    final erro = widget.validar(comunidade);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(comunidade);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final novo = widget.comunidade?.comuId == null;
    final erro = _erro;

    return ConfiguracaoDialogLayout(
      title: strings.translate(novo ? 'novaComunidade' : 'editarComunidade'),
      onSave: _confirmar,
      fields: [
        if (!novo) Text('${strings.translate('codigo')}: ${widget.comunidade!.comuId}'),
        TextField(
          controller: _nomeController,
          autofocus: novo,
          maxLength: widget.nomeMax,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: strings.translate('nome'),
            prefixIcon: ComunidadeView.icone(ComunidadeView.iconeComunidade, Icons.groups_outlined),
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue: _ctipId,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.translate('tipo')),
          items: [
            for (final tipo in widget.tipos)
              DropdownMenuItem(
                value: tipo.ctipId,
                child: Text(tipo.ctipNome, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() => _ctipId = value),
        ),
        DropdownButtonFormField<int>(
          initialValue: _cdenId,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.translate('denominacao')),
          items: [
            for (final denominacao in widget.denominacoes)
              DropdownMenuItem(
                value: denominacao.cdenId,
                child: Text(denominacao.cdenNome, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() => _cdenId = value),
        ),
        if (erro != null) Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
