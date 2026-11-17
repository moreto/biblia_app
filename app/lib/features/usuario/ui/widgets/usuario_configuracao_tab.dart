import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../use_case/usuario_usecase.dart';
import '../usuario_view.dart';
import '../usuario_viewmodel.dart';

/// Aba "Configurações" da tela "Meus dados" (`usuario_configuracao`): avisos por e-mail
/// ([UsuarioConfiguracaoOpcao.email]), leitura aberta e quantidade de registros guardados
/// ([UsuarioConfiguracaoQuantidade]). As escolhas ficam no viewmodel até o "Salvar" do botão inferior; "Descartar
/// alterações" volta para a configuração gravada. Sem configuração gravada, mostra os valores padrão com um aviso.
class UsuarioConfiguracaoTab extends StatelessWidget {
  const UsuarioConfiguracaoTab({super.key, required this.viewModel});

  final UsuarioViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gravada = viewModel.configuracao;
    if (viewModel.configuracaoEditada == null) return const SizedBox.shrink();
    final atualizadaEm = viewModel.data(gravada?.updateAt ?? gravada?.createdAt);

    return RefreshIndicator(
      onRefresh: viewModel.carregarCommand.execute,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (viewModel.configuracaoPadrao)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              color: scheme.secondaryContainer,
              child: ListTile(
                leading: UsuarioView.icone(
                  UsuarioView.iconeInformacao,
                  Icons.info_outline,
                  color: scheme.onSecondaryContainer,
                ),
                title: Text(
                  strings.translate('configuracaoPadraoAviso'),
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
            ),
          _secao(
            context,
            icone: UsuarioView.iconeAvisosEmail,
            fallback: Icons.mark_email_unread_outlined,
            titulo: strings.translate('avisosPorEmail'),
            children: [for (final opcao in UsuarioConfiguracaoOpcao.email) _opcao(context, strings, opcao)],
          ),
          _secao(
            context,
            icone: UsuarioConfiguracaoOpcao.emailLeitura.icone,
            fallback: Icons.menu_book_outlined,
            titulo: strings.translate('leituraBiblica'),
            children: [_opcao(context, strings, UsuarioConfiguracaoOpcao.leituraAberto)],
          ),
          _secao(
            context,
            icone: UsuarioView.iconeHistorico,
            fallback: Icons.history,
            titulo: strings.translate('historicoGuardado'),
            children: [for (final q in UsuarioConfiguracaoQuantidade.values) _quantidade(context, strings, q)],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    atualizadaEm == null ? '' : '${strings.translate('atualizadoEm')}: $atualizadaEm',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                if (viewModel.configuracaoAlterada && !viewModel.configuracaoPadrao)
                  TextButton.icon(
                    onPressed: viewModel.ocupado ? null : viewModel.descartarConfiguracao,
                    icon: UsuarioView.icone(UsuarioView.iconeDescartar, Icons.undo),
                    label: Text(strings.translate('descartarAlteracoes')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(
    BuildContext context, {
    required String icone,
    required IconData fallback,
    required String titulo,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                UsuarioView.icone(icone, fallback, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _opcao(BuildContext context, AppLocalizations strings, UsuarioConfiguracaoOpcao opcao) => SwitchListTile(
    secondary: UsuarioView.icone(opcao.icone, Icons.tune),
    title: Text(strings.translate(opcao.titulo)),
    subtitle: Text(strings.translate(opcao.descricao)),
    value: viewModel.opcao(opcao),
    onChanged: viewModel.ocupado ? null : (valor) => viewModel.alterarOpcao(opcao, valor),
  );

  Widget _quantidade(BuildContext context, AppLocalizations strings, UsuarioConfiguracaoQuantidade quantidade) {
    final atual = viewModel.quantidade(quantidade) ?? 0;
    return ListTile(
      leading: UsuarioView.icone(quantidade.icone, Icons.tune),
      title: Text(strings.translate(quantidade.titulo)),
      subtitle: Text(strings.translate(quantidade.descricao)),
      trailing: DropdownButton<int>(
        value: atual,
        underline: const SizedBox.shrink(),
        onChanged: viewModel.ocupado
            ? null
            : (valor) {
                if (valor != null) viewModel.alterarQuantidade(quantidade, valor);
              },
        items: [
          for (final valor in viewModel.opcoesQuantidade(quantidade))
            DropdownMenuItem(value: valor, child: Text('$valor')),
        ],
      ),
    );
  }
}
