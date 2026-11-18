import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/leitura/leitura_agenda_atividade_model.dart';
import '../../grupo_leitura/ui/grupo_leitura_view.dart';
import '../../grupo_leitura/ui/widgets/grupo_leitura_widgets.dart';
import '../../grupo_leitura_agenda/ui/grupo_leitura_agenda_view.dart';
import 'grupo_leitura_atividade_viewmodel.dart';

enum _Acao { editar, excluir }

/// Aba "Atividades" da tela de grupos de leitura: atividades do item da agenda selecionado
/// (`/v1/leitura-agenda-atividade/:lageId`), na ordem (`laatSeq`). "Atividades" no menu de um item da agenda abre a
/// aba com ele selecionado.
///
/// - Topo: seleção do grupo ([GrupoLeituraSelecao]) e do item da agenda, e o progresso (concluídas / total).
/// - Cada atividade mostra a marca de concluída, o texto, o livro e, se houver, a música e a oração vinculadas. Para
///   o dono, tocar na marca conclui/reabre (`concluirCommand`) e o menu tem "Editar" ([onEditar]) e "Excluir"
///   ([onExcluir], que confirma). A inclusão é pelo botão "Nova atividade" da parte inferior (só o dono).
/// - Primeiro carregamento: progresso; se falhar, "Tentar novamente". Sem itens na agenda: `nenhumItemAgenda`;
///   sem atividades: `nenhumaAtividade`.
///
/// Ícones (em `IconsMap.mdiIcons`): [iconeConcluida], [iconePendente], [iconeLivro], [iconeMusica], [iconeOracao]
/// e os de [GrupoLeituraView] e [GrupoLeituraAgendaView].
class GrupoLeituraAtividadeView extends StatelessWidget {
  const GrupoLeituraAtividadeView({
    super.key,
    required this.viewModel,
    required this.onEditar,
    required this.onExcluir,
  });

  final GrupoLeituraAtividadeViewmodel viewModel;
  final ValueChanged<LeituraAgendaAtividadeModel> onEditar;
  final ValueChanged<LeituraAgendaAtividadeModel> onExcluir;

  static const iconeConcluida = 'checkbox-marked-circle-outline';
  static const iconePendente = 'checkbox-blank-circle-outline';
  static const iconeLivro = 'book-open-variant';
  static const iconeMusica = 'music-note';
  static const iconeOracao = 'hands-pray';

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

    final atividades = viewModel.atividades;
    final String vazio;
    final String iconeVazio;
    if (viewModel.agenda.isEmpty) {
      vazio = 'nenhumItemAgenda';
      iconeVazio = GrupoLeituraView.iconeAgenda;
    } else {
      vazio = 'nenhumaAtividade';
      iconeVazio = GrupoLeituraView.iconeAtividades;
    }

    return Column(
      children: [
        if (viewModel.ocupado) const LinearProgressIndicator(),
        GrupoLeituraSelecao(
          grupos: grupos,
          selecionado: viewModel.grupo?.leitId,
          habilitado: !viewModel.ocupado,
          onSelecionar: viewModel.selecionarGrupoCommand.execute,
        ),
        if (viewModel.agenda.isNotEmpty) _selecaoItem(context),
        if (atividades.isNotEmpty) _progresso(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: atividades.isEmpty
                ? GrupoLeituraVazio(icone: iconeVazio, fallback: Icons.checklist, mensagem: vazio)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: atividades.length,
                    itemBuilder: (context, index) => _atividade(context, atividades[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _selecaoItem(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final selecionado = viewModel.item?.lageId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: DropdownButtonFormField<int>(
        key: ValueKey('item-$selecionado'),
        initialValue: selecionado,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('itemAgenda'),
          prefixIcon: GrupoLeituraView.icone(GrupoLeituraAgendaView.iconeData, Icons.event_outlined),
        ),
        items: [
          for (final item in viewModel.agenda)
            DropdownMenuItem(
              value: item.lageId,
              child: Text(item.lageTitulo ?? '#${item.lageId}', overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: viewModel.ocupado
            ? null
            : (lageId) => lageId == null ? null : viewModel.selecionarItemCommand.execute(lageId),
      ),
    );
  }

  Widget _progresso(BuildContext context) {
    final total = viewModel.atividades.length;
    final concluidas = viewModel.concluidas;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : concluidas / total,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('$concluidas/$total', style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }

  Widget _atividade(BuildContext context, LeituraAgendaAtividadeModel atividade) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dono = viewModel.podeAlterar;
    final habilitado = !viewModel.ocupado;
    final concluida = atividade.laatConcluida;
    final texto = atividade.laatTexto?.trim();
    final livro = viewModel.nomeLivro(atividade);

    final marca = GrupoLeituraView.icone(
      concluida ? iconeConcluida : iconePendente,
      concluida ? Icons.check_circle_outline : Icons.radio_button_unchecked,
      color: concluida ? scheme.primary : scheme.outline,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          children: [
            if (dono)
              IconButton(
                tooltip: strings.translate(concluida ? 'marcarPendente' : 'marcarConcluida'),
                onPressed: habilitado ? () => viewModel.concluirCommand.execute(atividade) : null,
                icon: marca,
              )
            else
              Padding(padding: const EdgeInsets.all(12), child: marca),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (texto != null && texto.isNotEmpty)
                      Text(
                        texto,
                        style: textTheme.bodyLarge?.copyWith(
                          decoration: concluida ? TextDecoration.lineThrough : null,
                          color: concluida ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        if (livro != null) _marcador(context, iconeLivro, Icons.menu_book_outlined, livro),
                        if (atividade.musiId != null)
                          _marcador(context, iconeMusica, Icons.music_note_outlined, strings.translate('musica')),
                        if (atividade.oracId != null)
                          _marcador(
                            context,
                            iconeOracao,
                            Icons.volunteer_activism_outlined,
                            strings.translate('oracao'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (dono)
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: habilitado,
                icon: GrupoLeituraView.icone(GrupoLeituraView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.editar => onEditar(atividade),
                  _Acao.excluir => onExcluir(atividade),
                },
                itemBuilder: (context) => [
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
              ),
          ],
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
        Text(texto, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
