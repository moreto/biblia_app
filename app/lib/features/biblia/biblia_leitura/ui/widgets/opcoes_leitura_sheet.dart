import 'package:app/config/leitura_preferencia.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../biblia_leitura_view.dart';
import '../biblia_leitura_viewmodel.dart';

/// Conteúdo do sheet "Opções de leitura", aberto pelo botão central da navegação da leitura: marcar o capítulo e
/// o que fazer ao passar a página (só com login) e os atalhos para as Configurações de leitura ([onConfiguracoes]),
/// onde ficam versão, fonte, brilho, setas, narração, tema, orientação e tags, e para as Configurações do app
/// ([onConfiguracoesApp]; sem login, abre o login).
class OpcoesLeituraSheet extends StatelessWidget {
  const OpcoesLeituraSheet({
    super.key,
    required this.viewModel,
    required this.onConfiguracoes,
    this.onConfiguracoesApp,
  });

  final BibliaLeituraViewmodel viewModel;

  /// Fecha o sheet e abre as Configurações de leitura.
  final VoidCallback onConfiguracoes;

  /// Fecha o sheet e abre as Configurações do app (sem login, o login); nulo esconde o item.
  final VoidCallback? onConfiguracoesApp;

  BibliaLeituraViewmodel get _vm => viewModel;

  /// Fecha o sheet e marca (ou desmarca) o capítulo; a confirmação aparece na tela da leitura.
  void _marcarCapitulo(BuildContext context) {
    Navigator.of(context).pop();
    _vm.marcarLidoCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.marcarLidoCommand]),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_vm.logado) ...[
            _botaoMarcar(context, strings),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(strings.translate('aoPassarPagina'), style: Theme.of(context).textTheme.labelLarge),
            ),
            _marcarAoPassar(strings),
            const SizedBox(height: 8),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: BibliaLeituraView.icone(BibliaLeituraView.iconeConfiguracoes, Icons.settings_outlined),
            title: Text(strings.translate('configuracoesLeitura')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              onConfiguracoes();
            },
          ),
          if (onConfiguracoesApp != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: Text(strings.translate('configuracoesApp')),
              subtitle: _vm.logado ? null : Text(strings.translate('entreParaAcessar')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                onConfiguracoesApp!();
              },
            ),
        ],
      ),
    );
  }

  Widget _botaoMarcar(BuildContext context, AppLocalizations strings) {
    final lido = _vm.lidoAtual?.completo ?? false;
    final marcando = _vm.marcarLidoCommand.running;
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: marcando || _vm.versiculos == null ? null : () => _marcarCapitulo(context),
      icon: marcando
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(lido ? Icons.check_circle : Icons.check_circle_outline),
      label: Text(strings.translate(lido ? 'desmarcarCapituloLido' : 'marcarCapituloLido')),
    );
  }

  /// Ao passar para o próximo capítulo: não marcar, perguntar ou marcar o anterior como lido.
  Widget _marcarAoPassar(AppLocalizations strings) => SegmentedButton<MarcarAoPassar>(
    showSelectedIcon: false,
    style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
    segments: [
      for (final (valor, chave) in [
        (MarcarAoPassar.nunca, 'naoMarcar'),
        (MarcarAoPassar.perguntar, 'perguntar'),
        (MarcarAoPassar.sempre, 'marcarLido'),
      ])
        ButtonSegment(
          value: valor,
          label: Text(strings.translate(chave), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
    selected: {_vm.marcarAoPassar},
    onSelectionChanged: (valores) => _vm.setMarcarAoPassar(valores.first),
  );
}
