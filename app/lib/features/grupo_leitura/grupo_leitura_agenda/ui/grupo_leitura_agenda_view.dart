import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/leitura/leitura_agenda_model.dart';
import '../../grupo_leitura/ui/grupo_leitura_view.dart';
import '../../grupo_leitura/ui/widgets/grupo_leitura_widgets.dart';
import 'grupo_leitura_agenda_viewmodel.dart';

enum _Acao { atividades, editar, excluir }

/// Aba "Agenda" da tela de grupos de leitura: itens da agenda do grupo selecionado (`/v1/leitura-agenda/:leitId`),
/// por data e hora (os sem data por último). "Agenda" no menu de um grupo abre a aba com ele selecionado.
///
/// - Topo: seleção do grupo ([GrupoLeituraSelecao]).
/// - Card: título, data e hora (ou "Sem data"), texto, repetição (com o fim) e lembrete, com os rótulos das
///   configurações da agenda traduzidos. Tocar abre as atividades do item ([onAtividades]);
///   para o dono, o menu tem também "Editar" ([onEditar]) e "Excluir" ([onExcluir], que confirma e remove as
///   atividades do item). A inclusão é pelo botão "Novo item" da parte inferior (só o dono).
/// - Primeiro carregamento: progresso; se falhar, "Tentar novamente". Sem itens: `nenhumItemAgenda`.
///
/// Ícones (em `IconsMap.mdiIcons`): [iconeData], [iconeSemData], [iconeLembrete], [iconeRepeticao],
/// [iconeFimRepeticao] e os de [GrupoLeituraView].
class GrupoLeituraAgendaView extends StatelessWidget {
  const GrupoLeituraAgendaView({
    super.key,
    required this.viewModel,
    required this.onEditar,
    required this.onExcluir,
    required this.onAtividades,
  });

  final GrupoLeituraAgendaViewmodel viewModel;
  final ValueChanged<LeituraAgendaModel> onEditar;
  final ValueChanged<LeituraAgendaModel> onExcluir;
  final ValueChanged<LeituraAgendaModel> onAtividades;

  static const iconeData = 'calendar-clock-outline';
  static const iconeSemData = 'calendar-blank-outline';
  static const iconeLembrete = 'bell-outline';
  static const iconeHora = 'clock-outline';
  static const iconeRepeticao = 'repeat';
  static const iconeFimRepeticao = 'calendar-end';

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: viewModel, builder: (context, _) => _conteudo(context));

  Widget _conteudo(BuildContext context) {
    final command = viewModel.carregarCommand;
    final grupos = viewModel.grupos;
    if (grupos == null && !command.error) return const Loading();
    if (grupos == null) return GrupoLeituraErro(command: command);
    if (grupos.isEmpty) {
      return const GrupoLeituraVazio(
        icone: GrupoLeituraView.iconeGrupo,
        fallback: Icons.menu_book_outlined,
        mensagem: 'nenhumGrupoLeitura',
      );
    }

    final agenda = viewModel.agenda;
    return Column(
      children: [
        if (viewModel.ocupado) const LinearProgressIndicator(),
        GrupoLeituraSelecao(
          grupos: grupos,
          selecionado: viewModel.selecionado?.leitId,
          habilitado: !viewModel.ocupado,
          onSelecionar: viewModel.selecionar,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: agenda.isEmpty
                ? const GrupoLeituraVazio(
                    icone: GrupoLeituraView.iconeAgenda,
                    fallback: Icons.calendar_month_outlined,
                    mensagem: 'nenhumItemAgenda',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: agenda.length,
                    itemBuilder: (context, index) => _item(context, agenda[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, LeituraAgendaModel item) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dataHora = viewModel.dataHora(item.lageDataHora);
    final repeticao = viewModel.rotuloRepeticao(item);
    final fimRepeticao = viewModel.rotuloFimRepeticao(item);
    final lembrete = viewModel.rotuloLembrete(item);
    final texto = item.lageTexto?.trim();
    final dono = viewModel.podeAlterar;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: viewModel.ocupado ? null : () => onAtividades(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: dataHora == null ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                foregroundColor: dataHora == null ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
                child: GrupoLeituraView.icone(
                  dataHora == null ? iconeSemData : iconeData,
                  dataHora == null ? Icons.event_busy_outlined : Icons.event_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.lageTitulo ?? '',
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dataHora ?? strings.translate('semData'),
                      style: textTheme.bodyMedium?.copyWith(color: scheme.primary),
                    ),
                    if (texto != null && texto.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          texto,
                          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (repeticao != null || lembrete != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            if (repeticao != null)
                              _marcador(
                                context,
                                iconeRepeticao,
                                Icons.repeat,
                                [
                                  strings.translate(repeticao),
                                  if (fimRepeticao != null) strings.translate(fimRepeticao),
                                ].join(' · '),
                              ),
                            if (lembrete != null)
                              _marcador(
                                context,
                                iconeLembrete,
                                Icons.notifications_none,
                                '${strings.translate('lembrete')}: ${strings.translate(lembrete)}',
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: !viewModel.ocupado,
                icon: GrupoLeituraView.icone(GrupoLeituraView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.atividades => onAtividades(item),
                  _Acao.editar => onEditar(item),
                  _Acao.excluir => onExcluir(item),
                },
                itemBuilder: (context) => [
                  grupoLeituraMenuItem(
                    _Acao.atividades,
                    GrupoLeituraView.icone(GrupoLeituraView.iconeAtividades, Icons.checklist),
                    strings.translate('atividades'),
                  ),
                  if (dono) ...[
                    grupoLeituraMenuItem(
                      _Acao.editar,
                      GrupoLeituraView.icone(GrupoLeituraView.iconeEditar, Icons.edit_outlined),
                      strings.translate('editar'),
                    ),
                    grupoLeituraMenuItem(
                      _Acao.excluir,
                      GrupoLeituraView.icone(GrupoLeituraView.iconeExcluir, Icons.delete_outline, color: scheme.error),
                      strings.translate('excluir'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _marcador(BuildContext context, String icone, IconData fallback, String texto) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GrupoLeituraView.icone(icone, fallback, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(texto, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
