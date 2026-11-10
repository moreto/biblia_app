import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../comunidade/ui/comunidade_view.dart';
import 'comunidade_endereco_viewmodel.dart';

/// Ações do menu de cada endereço.
enum _Acao { editar, excluir }

/// Aba "Endereços" da tela de comunidades: endereços da comunidade selecionada (`/v1/comunidade-endereco/:comuId`).
///
/// - Topo: seleção da comunidade (as do usuário, na ordem de "Minhas comunidades").
/// - Cada endereço mostra logradouro, bairro, município/UF e CEP; tocar edita ([onEditar]) e o menu tem editar e
///   excluir ([onExcluir]). A inclusão é pelo botão "Novo endereço" da parte inferior da tela.
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida e
///   a atualização, a troca de comunidade, a gravação e a exclusão mostram uma barra de progresso.
/// - Sem endereços: `nenhumEnderecoCadastrado`; sem comunidades: `nenhumaComunidadeCadastrada`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeEndereco], além de `ComunidadeView.iconeComunidade`,
/// `ComunidadeView.iconeAcoes`, `ComunidadeView.iconeEditar` e `ComunidadeView.iconeExcluir`.
class ComunidadeEnderecoView extends StatelessWidget {
  const ComunidadeEnderecoView({super.key, required this.viewModel, required this.onEditar, required this.onExcluir});

  final ComunidadeEnderecoViewmodel viewModel;
  final ValueChanged<ComunidadeEnderecoModel> onEditar;
  final ValueChanged<ComunidadeEnderecoModel> onExcluir;

  /// Ícone de cada endereço, da aba e do campo CEP.
  static const iconeEndereco = 'map-marker-outline';

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

    final enderecos = viewModel.enderecos;
    return Column(
      children: [
        if (viewModel.ocupado) const LinearProgressIndicator(),
        _selecao(context, strings),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: enderecos.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: _vazio(context, strings)),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: enderecos.length,
                    itemBuilder: (context, index) => _endereco(context, strings, enderecos[index]),
                  ),
          ),
        ),
      ],
    );
  }

  /// Seleção da comunidade, no topo (mesmo estilo da seleção de versão da leitura).
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
            icone(iconeEndereco, Icons.place_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumEnderecoCadastrado'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _endereco(BuildContext context, AppLocalizations strings, ComunidadeEnderecoModel endereco) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final local = viewModel.linhaLocal(endereco);
    final secundario = textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final habilitado = !viewModel.ocupado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? () => onEditar(endereco) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: icone(iconeEndereco, Icons.place_outlined, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(viewModel.linhaPrincipal(endereco), style: textTheme.titleMedium),
                    if (local != null) ...[const SizedBox(height: 4), Text(local, style: secundario)],
                    const SizedBox(height: 2),
                    Text('${strings.translate('cep')} ${viewModel.cep(endereco)}', style: secundario),
                  ],
                ),
              ),
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: habilitado,
                icon: icone(ComunidadeView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.editar => onEditar(endereco),
                  _Acao.excluir => onExcluir(endereco),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _Acao.editar,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: icone(ComunidadeView.iconeEditar, Icons.edit_outlined),
                      title: Text(strings.translate('editar')),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Acao.excluir,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: icone(ComunidadeView.iconeExcluir, Icons.delete_outline, color: scheme.error),
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
