import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/leitura/leitura_participante_model.dart';
import '../../grupo_leitura/ui/grupo_leitura_view.dart';
import '../../grupo_leitura/ui/widgets/grupo_leitura_widgets.dart';
import 'grupo_leitura_participante_viewmodel.dart';

/// Aba "Participantes" da tela de grupos de leitura: participantes do grupo selecionado
/// (`/v1/leitura-participante/:leitId`). "Participantes" no menu de um grupo abre a aba com ele selecionado.
///
/// - Topo: seleção do grupo ([GrupoLeituraSelecao]).
/// - Cada participante mostra as iniciais, o nome e o `@usuario`; o próprio usuário leva a marca "Você". O botão de
///   remover aparece para o dono (remove qualquer um) e, no próprio usuário, vira "Sair do grupo" ([onRemover], que
///   confirma). A inclusão é pelo botão "Adicionar participante" da parte inferior (só o dono).
/// - Primeiro carregamento: progresso; se falhar, "Tentar novamente". Depois disso a lista é mantida.
/// - Sem participantes: `nenhumParticipante`; sem grupos: `nenhumGrupoLeitura`.
///
/// Ícones (em `IconsMap.mdiIcons`): [iconeRemover], [iconeSair] e os de [GrupoLeituraView].
class GrupoLeituraParticipanteView extends StatelessWidget {
  const GrupoLeituraParticipanteView({super.key, required this.viewModel, required this.onRemover});

  final GrupoLeituraParticipanteViewmodel viewModel;
  final ValueChanged<LeituraParticipanteModel> onRemover;

  static const iconeRemover = 'account-remove-outline';
  static const iconeSair = 'exit-run';

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

    final participantes = viewModel.participantes;
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
            child: participantes.isEmpty
                ? const GrupoLeituraVazio(
                    icone: GrupoLeituraView.iconeParticipante,
                    fallback: Icons.people_outline,
                    mensagem: 'nenhumParticipante',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: participantes.length,
                    itemBuilder: (context, index) => _participante(context, participantes[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _participante(BuildContext context, LeituraParticipanteModel participante) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final nome = viewModel.nomeExibicao(udetNome: participante.udetNome, udetUsuario: participante.udetUsuario);
    final usuario = participante.udetUsuario?.trim();
    final voce = viewModel.ehUsuarioLogado(participante);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Text(viewModel.iniciais(udetNome: participante.udetNome, udetUsuario: participante.udetUsuario)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome ?? '#${participante.usuaId}',
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (usuario != null && usuario.isNotEmpty && usuario != nome)
                    Text('@$usuario', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (voce)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  label: Text(strings.translate('voce')),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            if (viewModel.podeRemover(participante))
              IconButton(
                tooltip: strings.translate(voce ? 'sairDoGrupo' : 'remover'),
                onPressed: viewModel.ocupado ? null : () => onRemover(participante),
                icon: GrupoLeituraView.icone(
                  voce ? iconeSair : iconeRemover,
                  voce ? Icons.logout : Icons.person_remove_outlined,
                  color: scheme.error,
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
