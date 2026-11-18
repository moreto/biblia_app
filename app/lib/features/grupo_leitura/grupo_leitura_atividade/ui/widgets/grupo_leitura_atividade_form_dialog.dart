import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/leitura/leitura_agenda_atividade_model.dart';
import '../../../../admin/configuracao/ui/widgets/configuracao_dialog_layout.dart';
import '../../../grupo_leitura/ui/grupo_leitura_view.dart';
import '../grupo_leitura_atividade_view.dart';
import '../grupo_leitura_atividade_viewmodel.dart';

/// Formulário de inclusão/alteração de atividade ([itemTitulo], o item da agenda, no topo): texto, livro da Bíblia
/// (opcional, "Sem livro") e concluída.
///
/// Ao salvar, `validar` do [viewModel] (regra do use case) devolve a chave do problema, mostrada no formulário; sem
/// problema, retorna o [LeituraAgendaAtividadeModel] preenchido (mantendo ordem, música e oração). `null` quando
/// cancelado.
class GrupoLeituraAtividadeFormDialog extends StatefulWidget {
  const GrupoLeituraAtividadeFormDialog({
    super.key,
    required this.viewModel,
    required this.lageId,
    required this.itemTitulo,
    this.atividade,
  });

  final GrupoLeituraAtividadeViewmodel viewModel;
  final int lageId;
  final String itemTitulo;

  /// Atividade em alteração; nula na inclusão.
  final LeituraAgendaAtividadeModel? atividade;

  static Future<LeituraAgendaAtividadeModel?> show(
    BuildContext context, {
    required GrupoLeituraAtividadeViewmodel viewModel,
    required int lageId,
    required String itemTitulo,
    LeituraAgendaAtividadeModel? atividade,
  }) => ConfiguracaoDialogLayout.show<LeituraAgendaAtividadeModel>(
    context,
    titulo: AppLocalizations.of(context).translate(atividade?.laatId == null ? 'novaAtividade' : 'editarAtividade'),
    form: GrupoLeituraAtividadeFormDialog(
      viewModel: viewModel,
      lageId: lageId,
      itemTitulo: itemTitulo,
      atividade: atividade,
    ),
  );

  @override
  State<GrupoLeituraAtividadeFormDialog> createState() => _GrupoLeituraAtividadeFormDialogState();
}

class _GrupoLeituraAtividadeFormDialogState extends State<GrupoLeituraAtividadeFormDialog> {
  GrupoLeituraAtividadeViewmodel get _vm => widget.viewModel;

  late final _texto = TextEditingController(text: widget.atividade?.laatTexto);

  /// O livro só vale como seleção inicial se estiver entre as opções (o dropdown exige).
  late int? _livrId = _vm.livros.any((l) => l.livrId == widget.atividade?.livrId) ? widget.atividade?.livrId : null;
  late bool _concluida = widget.atividade?.laatConcluida ?? false;
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _confirmar() {
    final atual = widget.atividade;
    final atividade = LeituraAgendaAtividadeModel(
      laatId: atual?.laatId,
      lageId: widget.lageId,
      livrId: _livrId,
      musiId: atual?.musiId,
      oracId: atual?.oracId,
      laatSeq: atual?.laatSeq ?? 0,
      laatTexto: _texto.text,
      laatConcluida: _concluida,
    );
    final erro = _vm.validar(atividade);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(atividade);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final erro = _erro;

    return ConfiguracaoDialogLayout(
      onSave: _confirmar,
      fields: [
        Text(widget.itemTitulo, style: Theme.of(context).textTheme.titleSmall),
        TextField(
          controller: _texto,
          autofocus: widget.atividade == null,
          maxLines: 4,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.translate('texto'),
            prefixIcon: GrupoLeituraView.icone(GrupoLeituraView.iconeDescricao, Icons.notes_outlined),
          ),
        ),
        DropdownButtonFormField<int?>(
          initialValue: _livrId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: strings.translate('livro'),
            prefixIcon: GrupoLeituraView.icone(GrupoLeituraAtividadeView.iconeLivro, Icons.menu_book_outlined),
          ),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(strings.translate('semLivro'))),
            for (final livro in _vm.livros)
              DropdownMenuItem<int?>(
                value: livro.livrId,
                child: Text(livro.livrNome, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() => _livrId = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _concluida,
          onChanged: (valor) => setState(() => _concluida = valor),
          secondary: GrupoLeituraView.icone(GrupoLeituraAtividadeView.iconeConcluida, Icons.check_circle_outline),
          title: Text(strings.translate('concluida')),
        ),
        if (erro != null) Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
