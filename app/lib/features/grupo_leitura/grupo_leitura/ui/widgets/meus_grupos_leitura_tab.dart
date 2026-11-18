import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/leitura/leitura_model.dart';
import '../grupo_leitura_view.dart';
import '../grupo_leitura_viewmodel.dart';
import 'grupo_leitura_widgets.dart';

enum _Acao { participantes, agenda, editar, excluir }

/// Aba "Meus grupos": grupos de que o usuário é dono ou participante, por nome.
///
/// Card com nome, descrição e o papel do usuário (dono, com destaque, ou participante). Tocar no card de um grupo
/// do usuário abre o formulário ([onEditar]); o menu leva às abas "Participantes" e "Agenda" com o grupo
/// selecionado e, para o dono, tem "Editar" e "Excluir" ([onExcluir], que confirma).
///
/// Primeiro carregamento: progresso; se falhar, "Tentar novamente". Depois disso a lista é mantida e as gravações
/// mostram uma barra de progresso. Sem grupos: `nenhumGrupoLeitura`.
class MeusGruposLeituraTab extends StatelessWidget {
  const MeusGruposLeituraTab({
    super.key,
    required this.viewModel,
    required this.onEditar,
    required this.onExcluir,
    required this.onParticipantes,
    required this.onAgenda,
  });

  final GrupoLeituraViewmodel viewModel;
  final ValueChanged<LeituraModel> onEditar;
  final ValueChanged<LeituraModel> onExcluir;
  final ValueChanged<LeituraModel> onParticipantes;
  final ValueChanged<LeituraModel> onAgenda;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: viewModel, builder: (context, _) => _conteudo(context));

  Widget _conteudo(BuildContext context) {
    final command = viewModel.gruposCommand;
    final grupos = viewModel.grupos;
    if (grupos == null && !command.error) return const Loading();
    if (grupos == null) return GrupoLeituraErro(command: command);

    return Column(
      children: [
        if (command.running || viewModel.gravando) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: grupos.isEmpty
                ? const GrupoLeituraVazio(
                    icone: GrupoLeituraView.iconeGrupo,
                    fallback: Icons.menu_book_outlined,
                    mensagem: 'nenhumGrupoLeitura',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: grupos.length,
                    itemBuilder: (context, index) => _grupo(context, grupos[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _grupo(BuildContext context, LeituraModel grupo) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dono = grupo.leitDono;
    final descricao = grupo.leitDescricao?.trim();
    final habilitado = !viewModel.gravando;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: dono && habilitado ? () => onEditar(grupo) : () => onAgenda(grupo),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: dono ? scheme.primaryContainer : scheme.secondaryContainer,
                foregroundColor: dono ? scheme.onPrimaryContainer : scheme.onSecondaryContainer,
                child: GrupoLeituraView.icone(GrupoLeituraView.iconeGrupo, Icons.menu_book_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(grupo.leitNome, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 2),
                    if (descricao != null && descricao.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          descricao,
                          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GrupoLeituraView.icone(
                          dono ? GrupoLeituraView.iconeDono : GrupoLeituraView.iconeParticipante,
                          dono ? Icons.star_outline : Icons.people_outline,
                          size: 16,
                          color: dono ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          strings.translate(viewModel.papel(grupo)),
                          style: textTheme.labelMedium?.copyWith(
                            color: dono ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: habilitado,
                icon: GrupoLeituraView.icone(GrupoLeituraView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.participantes => onParticipantes(grupo),
                  _Acao.agenda => onAgenda(grupo),
                  _Acao.editar => onEditar(grupo),
                  _Acao.excluir => onExcluir(grupo),
                },
                itemBuilder: (context) => [
                  grupoLeituraMenuItem(
                    _Acao.participantes,
                    GrupoLeituraView.icone(GrupoLeituraView.iconeParticipante, Icons.people_outline),
                    strings.translate('participantes'),
                  ),
                  grupoLeituraMenuItem(
                    _Acao.agenda,
                    GrupoLeituraView.icone(GrupoLeituraView.iconeAgenda, Icons.calendar_month_outlined),
                    strings.translate('agenda'),
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
}
