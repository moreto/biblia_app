import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../../../../../data/model/comunidade/comunidade_humanograma_model.dart';
import '../../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../../comunidade/ui/comunidade_view.dart';
import '../comunidade_lista_viewmodel.dart';

/// Detalhe de uma comunidade da tela "Encontrar comunidades", aberto ao tocar no card (no `DialogBottomSheet`, [show]).
///
/// - Topo (já conhecido pela lista): ícone do tipo, nome, tipo e denominação.
/// - Seções carregadas ao abrir (`detalheCommand`, em paralelo): membros ativos (só a quantidade), endereços (todos,
///   com CEP), contatos (cada campo preenchido; tocar abre o discador, WhatsApp, e-mail ou navegador pelo
///   `acessarCommand`, erro em SnackBar) e liderança (humanograma: cargo e nome).
/// - Seção que falhou mostra `naoFoiPossivelCarregar`; vazia, a mensagem própria (`nenhumEnderecoCadastrado`,
///   `nenhumContatoCadastrado`, `nenhumaLiderancaCadastrada`).
///
/// Ícones (em `IconsMap.mdiIcons`): [iconeMembros], [iconeEndereco], [iconeContato], [iconeLideranca] e o
/// `ContatoCampo.icone` de cada contato.
class ComunidadeDetalheDialog extends StatefulWidget {
  const ComunidadeDetalheDialog({super.key, required this.viewModel, required this.comunidade});

  final ComunidadeListaViewmodel viewModel;
  final ComunidadeLocalModel comunidade;

  static const iconeMembros = 'account-multiple-outline';
  static const iconeEndereco = 'map-marker-outline';
  static const iconeContato = 'card-account-phone-outline';
  static const iconeLideranca = 'sitemap-outline';

  static Future<void> show(
    BuildContext context, {
    required ComunidadeListaViewmodel viewModel,
    required ComunidadeLocalModel comunidade,
  }) => DialogSheet.show<void>(
    context,
    cabecalho: _Cabecalho(viewModel: viewModel, comunidade: comunidade),
    conteudo: ComunidadeDetalheDialog(viewModel: viewModel, comunidade: comunidade),
  );

  @override
  State<ComunidadeDetalheDialog> createState() => _ComunidadeDetalheDialogState();
}

class _ComunidadeDetalheDialogState extends State<ComunidadeDetalheDialog> {
  ComunidadeListaViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.acessarCommand.addListener(_onAcessar);
    // Depois do primeiro frame: o comando notifica a tela da lista, que está em build quando o dialog abre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _vm.detalheCommand.execute(widget.comunidade.comuId);
    });
  }

  @override
  void dispose() {
    _vm.acessarCommand.removeListener(_onAcessar);
    super.dispose();
  }

  void _onAcessar() {
    final command = _vm.acessarCommand;
    if (!mounted) return;
    if (command.error) {
      final mensagem = ComunidadeView.mensagemErro(command.result);
      command.clearResult();
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
    } else if (command.completed) {
      command.clearResult();
    }
  }

  static Widget _icone(String chave, IconData fallback, {Color? color, double? size}) =>
      ComunidadeView.icone(chave, fallback, color: color, size: size);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final comunidade = widget.comunidade;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final detalhe = _vm.detalheDe == comunidade.comuId ? _vm.detalhe : null;
        if (detalhe == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _membros(context, strings, detalhe.membrosAtivos),
            _secao(
              context,
              strings,
              titulo: 'enderecos',
              icone: ComunidadeDetalheDialog.iconeEndereco,
              fallback: Icons.place_outlined,
              itens: detalhe.enderecos,
              vazio: 'nenhumEnderecoCadastrado',
              item: (e) => _endereco(context, e as ComunidadeEnderecoModel),
            ),
            _secao(
              context,
              strings,
              titulo: 'contatos',
              icone: ComunidadeDetalheDialog.iconeContato,
              fallback: Icons.contact_phone_outlined,
              itens: detalhe.contatos,
              vazio: 'nenhumContatoCadastrado',
              item: (c) => _contato(context, strings, c as ComunidadeContatoModel),
            ),
            _secao(
              context,
              strings,
              titulo: 'lideranca',
              icone: ComunidadeDetalheDialog.iconeLideranca,
              fallback: Icons.account_tree_outlined,
              itens: detalhe.lideranca,
              vazio: 'nenhumaLiderancaCadastrada',
              item: (p) => _pessoa(context, p as ComunidadeHumanogramaModel),
            ),
            DialogSheet.acoes([
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('fechar'))),
            ]),
          ],
        );
      },
    );
  }

  Widget _titulo(BuildContext context, String texto, String icone, IconData fallback) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          _icone(icone, fallback, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(texto, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
        ],
      ),
    );
  }

  Widget _aviso(BuildContext context, String texto) => Padding(
    padding: const EdgeInsets.only(left: 28, top: 2),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );

  Widget _membros(BuildContext context, AppLocalizations strings, int? ativos) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          _icone(ComunidadeDetalheDialog.iconeMembros, Icons.people_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ativos == null
                  ? '${strings.translate('membrosAtivos')}: ${strings.translate('naoFoiPossivelCarregar')}'
                  : '${strings.translate('membrosAtivos')}: $ativos',
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(
    BuildContext context,
    AppLocalizations strings, {
    required String titulo,
    required String icone,
    required IconData fallback,
    required List<Object>? itens,
    required String vazio,
    required Widget Function(Object) item,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo(context, strings.translate(titulo), icone, fallback),
        if (itens == null)
          _aviso(context, strings.translate('naoFoiPossivelCarregar'))
        else if (itens.isEmpty)
          _aviso(context, strings.translate(vazio))
        else
          for (final i in itens) item(i),
      ],
    );
  }

  Widget _endereco(BuildContext context, ComunidadeEnderecoModel endereco) {
    final linhas = _vm.linhasDoEndereco(endereco);
    final secundario = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(linhas.principal),
          if (linhas.local != null) Text(linhas.local!, style: secundario),
          Text('${AppLocalizations.of(context).translate('cep')} ${linhas.cep}', style: secundario),
        ],
      ),
    );
  }

  Widget _contato(BuildContext context, AppLocalizations strings, ComunidadeContatoModel contato) {
    final scheme = Theme.of(context).colorScheme;
    final abrindo = _vm.acessarCommand.running;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          for (final (campo, valor) in _vm.preenchidos(contato))
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: _icone(campo.icone, Icons.contact_page_outlined, color: scheme.primary),
              title: Text(_vm.exibicao(campo, valor), overflow: TextOverflow.ellipsis),
              subtitle: Text(strings.translate(campo.rotulo)),
              onTap: !abrindo && _vm.acessivel(campo, valor) ? () => _vm.acessarCommand.execute((campo, valor)) : null,
            ),
        ],
      ),
    );
  }

  Widget _pessoa(BuildContext context, ComunidadeHumanogramaModel pessoa) {
    final cargo = pessoa.chcaCargo?.trim();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            if (cargo != null && cargo.isNotEmpty)
              TextSpan(
                text: '$cargo: ',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            TextSpan(text: pessoa.chumNome),
          ],
        ),
      ),
    );
  }
}

/// Topo do detalhe (título do sheet): ícone do tipo, nome, tipo e denominação.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.viewModel, required this.comunidade});

  final ComunidadeListaViewmodel viewModel;
  final ComunidadeLocalModel comunidade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final descricao = viewModel.descricao(comunidade);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: ComunidadeView.iconeDaComunidade(comunidade.ctipIcone, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comunidade.comuNome, style: textTheme.titleLarge),
              if (descricao != null)
                Text(descricao, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
