import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/comunidade/comunidade_model.dart';
import '../../use_case/comunidade_usecase.dart';
import '../comunidade_view.dart';
import '../comunidade_viewmodel.dart';

/// Ações do menu de cada comunidade.
enum _Acao { editar, enderecos, contatos, excluir }

/// Aba "Minhas comunidades": comunidades cadastradas pelo usuário, com tipo e denominação.
///
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida e
///   a atualização (AppBar ou puxar para baixo), a gravação e a exclusão mostram uma barra de progresso.
/// - Tocar no card edita ([onEditar]); o menu do card tem editar, endereços ([onEnderecos], abre a aba "Endereços"
///   com a comunidade selecionada), contatos ([onContatos], idem na aba "Contatos") e excluir ([onExcluir]).
class MinhasComunidadesTab extends StatelessWidget {
  const MinhasComunidadesTab({
    super.key,
    required this.viewModel,
    required this.onEditar,
    required this.onExcluir,
    required this.onEnderecos,
    required this.onContatos,
  });

  final ComunidadeViewmodel viewModel;
  final ValueChanged<ComunidadeModel> onEditar;
  final ValueChanged<ComunidadeModel> onExcluir;
  final ValueChanged<ComunidadeModel> onEnderecos;
  final ValueChanged<ComunidadeModel> onContatos;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final command = viewModel.minhasCommand;
    final comunidades = viewModel.minhas;

    if (comunidades == null && command.running) return const Loading();
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
                icon: ComunidadeView.icone(ComunidadeView.iconeAtualizar, Icons.refresh),
                label: Text(strings.translate('tentarNovamente')),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (command.running || viewModel.gravando) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: comunidades.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: _vazio(context, strings)),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: comunidades.length,
                    itemBuilder: (context, index) => _comunidade(context, strings, comunidades[index]),
                  ),
          ),
        ),
      ],
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
            ComunidadeView.icone(
              ComunidadeView.iconeComunidade,
              Icons.groups_outlined,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumaComunidadeCadastrada'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _comunidade(BuildContext context, AppLocalizations strings, ComunidadeResumo resumo) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final descricao = viewModel.descricao(resumo);
    final comunidade = resumo.comunidade;
    final habilitado = !viewModel.gravando;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? () => onEditar(comunidade) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: ComunidadeView.icone(
                  ComunidadeView.iconeComunidade,
                  Icons.groups_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comunidade.comuNome, style: textTheme.titleMedium),
                    if (descricao != null) ...[
                      const SizedBox(height: 4),
                      Text(descricao, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: habilitado,
                icon: ComunidadeView.icone(ComunidadeView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.editar => onEditar(comunidade),
                  _Acao.enderecos => onEnderecos(comunidade),
                  _Acao.contatos => onContatos(comunidade),
                  _Acao.excluir => onExcluir(comunidade),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _Acao.editar,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ComunidadeView.icone(ComunidadeView.iconeEditar, Icons.edit_outlined),
                      title: Text(strings.translate('editar')),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Acao.enderecos,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ComunidadeView.icone(ComunidadeAba.enderecos.icone, Icons.place_outlined),
                      title: Text(strings.translate('enderecos')),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Acao.contatos,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ComunidadeView.icone(ComunidadeAba.contatos.icone, Icons.contact_phone_outlined),
                      title: Text(strings.translate('contatos')),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Acao.excluir,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ComunidadeView.icone(
                        ComunidadeView.iconeExcluir,
                        Icons.delete_outline,
                        color: scheme.error,
                      ),
                      title: Text(strings.translate('excluir')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
