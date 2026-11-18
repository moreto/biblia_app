import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../../../admin/configuracao/ui/widgets/configuracao_dialog_layout.dart';
import '../../../grupo_leitura/ui/grupo_leitura_view.dart';
import '../grupo_leitura_agenda_view.dart';
import '../grupo_leitura_agenda_viewmodel.dart';

/// Formulário de inclusão/alteração de item da agenda ([grupoNome] no topo): título, texto, data, hora e lembrete.
///
/// Data, hora e lembrete abrem os seletores do sistema e podem ser limpos; a hora só vale com data (a API grava data
/// e hora num campo só). Ao salvar, `validar` do [viewModel] (regra do use case) devolve a chave do problema,
/// mostrada no formulário; sem problema, retorna o [LeituraAgendaModel] preenchido (mantendo os campos que a tela
/// não edita). `null` quando cancelado.
class GrupoLeituraAgendaFormDialog extends StatefulWidget {
  const GrupoLeituraAgendaFormDialog({
    super.key,
    required this.viewModel,
    required this.leitId,
    required this.grupoNome,
    this.item,
  });

  final GrupoLeituraAgendaViewmodel viewModel;
  final int leitId;
  final String grupoNome;

  /// Item em alteração; nulo na inclusão.
  final LeituraAgendaModel? item;

  static Future<LeituraAgendaModel?> show(
    BuildContext context, {
    required GrupoLeituraAgendaViewmodel viewModel,
    required int leitId,
    required String grupoNome,
    LeituraAgendaModel? item,
  }) => ConfiguracaoDialogLayout.show<LeituraAgendaModel>(
    context,
    titulo: AppLocalizations.of(context).translate(item?.lageId == null ? 'novoItemAgenda' : 'editarItemAgenda'),
    form: GrupoLeituraAgendaFormDialog(viewModel: viewModel, leitId: leitId, grupoNome: grupoNome, item: item),
  );

  @override
  State<GrupoLeituraAgendaFormDialog> createState() => _GrupoLeituraAgendaFormDialogState();
}

class _GrupoLeituraAgendaFormDialogState extends State<GrupoLeituraAgendaFormDialog> {
  GrupoLeituraAgendaViewmodel get _vm => widget.viewModel;

  late final _titulo = TextEditingController(text: widget.item?.lageTitulo);
  late final _texto = TextEditingController(text: widget.item?.lageTexto);
  late DateTime? _data = widget.item?.lageDataHora;
  late ({int hora, int minuto})? _hora = switch (widget.item?.lageDataHora) {
    null => null,
    final d => (hora: d.hour, minuto: d.minute),
  };
  late ({int hora, int minuto})? _lembrete = _vm.horaMinuto(widget.item?.lageLembrete);
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 10),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<({int hora, int minuto})?> _escolherHora(({int hora, int minuto})? atual) async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: atual == null ? TimeOfDay.now() : TimeOfDay(hour: atual.hora, minute: atual.minuto),
    );
    return escolhida == null ? null : (hora: escolhida.hour, minuto: escolhida.minute);
  }

  String? _formatar(({int hora, int minuto})? hora) =>
      hora == null ? null : _vm.hora(_vm.horaApi(hora.hora, hora.minuto));

  void _confirmar() {
    final atual = widget.item;
    final lembrete = _lembrete;
    final item = LeituraAgendaModel(
      lageId: atual?.lageId,
      leitId: widget.leitId,
      lageTitulo: _titulo.text,
      lageTexto: _texto.text,
      lageDataHora: _vm.juntar(_data, _hora),
      lageHoraAtividade: atual?.lageHoraAtividade,
      lageRepete: atual?.lageRepete,
      lageFimRepete: atual?.lageFimRepete,
      lageLembrete: lembrete == null ? null : _vm.horaApi(lembrete.hora, lembrete.minuto),
    );
    final erro = _vm.validar(item);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(item);
  }

  /// Campo só leitura que abre um seletor; o X limpa o valor.
  Widget _seletor({
    required String rotulo,
    required String? valor,
    required String icone,
    required IconData fallback,
    required VoidCallback? onTap,
    required VoidCallback onLimpar,
  }) {
    final strings = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        isEmpty: valor == null,
        decoration: InputDecoration(
          labelText: strings.translate(rotulo),
          prefixIcon: GrupoLeituraView.icone(icone, fallback),
          enabled: onTap != null,
          suffixIcon: valor == null
              ? null
              : IconButton(tooltip: strings.translate('limpar'), onPressed: onLimpar, icon: const Icon(Icons.close)),
        ),
        child: Text(valor ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final erro = _erro;

    return ConfiguracaoDialogLayout(
      onSave: _confirmar,
      fields: [
        Text(widget.grupoNome, style: Theme.of(context).textTheme.titleSmall),
        TextField(
          controller: _titulo,
          autofocus: widget.item == null,
          maxLength: _vm.tituloMax,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: strings.translate('titulo'),
            prefixIcon: GrupoLeituraView.icone(GrupoLeituraView.iconeAgenda, Icons.calendar_month_outlined),
          ),
        ),
        TextField(
          controller: _texto,
          maxLength: _vm.textoMax,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: strings.translate('texto'),
            prefixIcon: GrupoLeituraView.icone(GrupoLeituraView.iconeDescricao, Icons.notes_outlined),
          ),
        ),
        _seletor(
          rotulo: 'data',
          valor: _vm.data(_data),
          icone: GrupoLeituraAgendaView.iconeData,
          fallback: Icons.event_outlined,
          onTap: _escolherData,
          onLimpar: () => setState(() {
            _data = null;
            _hora = null;
          }),
        ),
        _seletor(
          rotulo: 'hora',
          valor: _formatar(_hora),
          icone: GrupoLeituraAgendaView.iconeHora,
          fallback: Icons.schedule,
          onTap: _data == null
              ? null
              : () async {
                  final hora = await _escolherHora(_hora);
                  if (hora != null) setState(() => _hora = hora);
                },
          onLimpar: () => setState(() => _hora = null),
        ),
        _seletor(
          rotulo: 'lembrete',
          valor: _formatar(_lembrete),
          icone: GrupoLeituraAgendaView.iconeLembrete,
          fallback: Icons.notifications_none,
          onTap: () async {
            final hora = await _escolherHora(_lembrete);
            if (hora != null) setState(() => _lembrete = hora);
          },
          onLimpar: () => setState(() => _lembrete = null),
        ),
        if (erro != null) Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    );
  }
}
