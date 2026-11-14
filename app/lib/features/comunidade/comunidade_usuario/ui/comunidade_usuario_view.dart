import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_usuario_model.dart';
import '../../comunidade/ui/comunidade_view.dart';
import 'comunidade_usuario_viewmodel.dart';
import 'widgets/comunidade_usuario_adicionar_dialog.dart';

/// Ações do menu de cada usuário.
enum _Acao { ativar, remover }

/// Aba "Usuários" da tela de comunidades: usuários vinculados à comunidade selecionada
/// (`/v1/comunidade-usuario/:comuId`). "Usuários" no menu de uma comunidade abre a aba com ela selecionada.
///
/// - Topo: seleção da comunidade (as do usuário, na ordem de "Minhas comunidades").
/// - Cada usuário mostra as iniciais, o nome, o `@usuario` e, se inativo, a marca "Inativo" (ativos primeiro). O
///   menu tem ativar/desativar e remover ([onRemover], que confirma). A inclusão é pelo botão "Adicionar usuário"
///   da parte inferior da tela ([ComunidadeUsuarioAdicionarDialog]).
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida e
///   a atualização, a troca de comunidade e as gravações mostram uma barra de progresso.
/// - Sem usuários: `nenhumUsuarioNaComunidade`; sem comunidades: `nenhumaComunidadeCadastrada`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeUsuarios], [iconeAtivar], [iconeDesativar] e [iconeRemover], além de
/// `ComunidadeView.iconeComunidade`, `ComunidadeView.iconeAtualizar`, `ComunidadeView.iconeAcoes` e os de
/// [ComunidadeUsuarioAdicionarDialog].
class ComunidadeUsuarioView extends StatelessWidget {
  const ComunidadeUsuarioView({super.key, required this.viewModel, required this.onRemover});

  final ComunidadeUsuarioViewmodel viewModel;
  final ValueChanged<ComunidadeUsuarioModel> onRemover;

  /// Ícone da aba e da lista vazia.
  static const iconeUsuarios = 'account-multiple-outline';
  static const iconeAtivar = 'account-check-outline';
  static const iconeDesativar = 'account-cancel-outline';
  static const iconeRemover = 'account-remove-outline';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      ComunidadeView.icone(chave, fallback, color: color, size: size);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: viewModel, builder: (context, _) => _conteudo(context));
  }

  Widget _conteudo(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final command = viewModel.carregarCommand;
    final comunidades = viewModel.comunidades;

    if (comunidades == null && !command.error) return const Loading();
    if (comunidades == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.translate(ComunidadeView.mensagemErro(command.result)), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: command.running ? null : command.execute,
                icon: icone(ComunidadeView.iconeAtualizar, Icons.refresh),
                label: Text(strings.translate('tentarNovamente')),
              ),
            ],
          ),
        ),
      );
    }
    if (comunidades.isEmpty) {
      return Center(child: Text(strings.translate('nenhumaComunidadeCadastrada')));
    }

    final usuarios = viewModel.usuarios;
    return Column(
      children: [
        if (viewModel.ocupado) const LinearProgressIndicator(),
        _selecao(context, strings),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: usuarios.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: _vazio(context, strings)),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) => _usuario(context, strings, usuarios[index]),
                  ),
          ),
        ),
      ],
    );
  }

  /// Seleção da comunidade, no topo (mesmo estilo das abas "Endereços" e "Contatos").
  Widget _selecao(BuildContext context, AppLocalizations strings) {
    final selecionada = viewModel.selecionada?.comunidade.comuId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<int>(
        key: ValueKey(selecionada),
        initialValue: selecionada,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('comunidade'),
          prefixIcon: icone(ComunidadeView.iconeComunidade, Icons.groups_outlined),
        ),
        items: [
          for (final resumo in viewModel.comunidades ?? const [])
            DropdownMenuItem(
              value: resumo.comunidade.comuId,
              child: Text(resumo.comunidade.comuNome, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: viewModel.ocupado ? null : (comuId) => comuId == null ? null : viewModel.selecionar(comuId),
      ),
    );
  }

  Widget _vazio(BuildContext context, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icone(iconeUsuarios, Icons.people_outline, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumUsuarioNaComunidade'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _usuario(BuildContext context, AppLocalizations strings, ComunidadeUsuarioModel membro) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final habilitado = !viewModel.ocupado;
    final nome = viewModel.nomeExibicao(udetNome: membro.udetNome, udetUsuario: membro.udetUsuario);
    final usuario = membro.udetUsuario?.trim();
    final ativo = membro.cusuAtivo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: ativo ? scheme.primaryContainer : scheme.surfaceContainerHighest,
              foregroundColor: ativo ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              child: Text(viewModel.iniciais(udetNome: membro.udetNome, udetUsuario: membro.udetUsuario)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome ?? '#${membro.usuaId}',
                    style: textTheme.titleMedium?.copyWith(color: ativo ? null : scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (usuario != null && usuario.isNotEmpty && usuario != nome)
                    Text('@$usuario', style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (!ativo)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  label: Text(strings.translate('inativo')),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            PopupMenuButton<_Acao>(
              tooltip: strings.translate('acoes'),
              enabled: habilitado,
              icon: icone(ComunidadeView.iconeAcoes, Icons.more_vert),
              onSelected: (acao) => switch (acao) {
                _Acao.ativar => viewModel.ativarCommand.execute(membro),
                _Acao.remover => onRemover(membro),
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _Acao.ativar,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ativo
                        ? icone(iconeDesativar, Icons.person_off_outlined)
                        : icone(iconeAtivar, Icons.how_to_reg_outlined),
                    title: Text(strings.translate(ativo ? 'desativar' : 'ativar')),
                  ),
                ),
                PopupMenuItem(
                  value: _Acao.remover,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: icone(iconeRemover, Icons.person_remove_outlined, color: scheme.error),
                    title: Text(strings.translate('remover')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
