import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../use_case/comunidade_usecase.dart';
import '../comunidade_view.dart';
import '../comunidade_viewmodel.dart';

/// Aba "Minhas comunidades": comunidades cadastradas pelo usuário, com tipo e denominação.
///
/// Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida e
/// a atualização (AppBar ou puxar para baixo) mostra uma barra de progresso.
class MinhasComunidadesTab extends StatelessWidget {
  const MinhasComunidadesTab({super.key, required this.viewModel});

  final ComunidadeViewmodel viewModel;

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
        if (command.running) const LinearProgressIndicator(),
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
                    itemBuilder: (context, index) => _comunidade(context, comunidades[index]),
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

  Widget _comunidade(BuildContext context, ComunidadeResumo resumo) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final descricao = viewModel.descricao(resumo);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  Text(resumo.comunidade.comuNome, style: textTheme.titleMedium),
                  if (descricao != null) ...[
                    const SizedBox(height: 4),
                    Text(descricao, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
