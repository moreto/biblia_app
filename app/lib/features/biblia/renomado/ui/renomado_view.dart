import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/renomado_model.dart';
import 'renomado_viewmodel.dart';

/// Lista de renomados (`GET /v1/renomado`), na ordem definida pelo use case.
///
/// - Primeiro carregamento: indicador de progresso; se falhar, mensagem com "Tentar novamente".
/// - Depois disso, a lista é mantida: a atualização (AppBar ou puxar para baixo) mostra uma barra de progresso
///   e um erro aparece em SnackBar.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeRenomado] e [iconeAtualizar].
class RenomadoView extends StatefulWidget {
  const RenomadoView({super.key, required this.viewModel});

  final RenomadoViewmodel viewModel;

  /// Ícone de cada renomado e da lista vazia; também serve de `menu_icone` do menu da tela.
  static const iconeRenomado = 'account-star-outline';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  @override
  State<RenomadoView> createState() => _RenomadoViewState();
}

class _RenomadoViewState extends State<RenomadoView> {
  RenomadoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.listarCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant RenomadoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.listarCommand.removeListener(_onResult);
    _vm.listarCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    _vm.listarCommand.removeListener(_onResult);
    super.dispose();
  }

  /// Erros de atualização viram SnackBar; o erro do primeiro carregamento fica na tela, em [_erroCarregamento].
  void _onResult() {
    final command = _vm.listarCommand;
    if (!command.error || _vm.renomados == null) return;

    final mensagem = RenomadoView.mensagemErro(command.result);
    command.clearResult();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.listarCommand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(RenomadoView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: RenomadoView.icone(RenomadoView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RenomadoView.icone(RenomadoView.iconeRenomado, Icons.star_outline, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumRenomadoCadastrado'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _renomado(RenomadoModel renomado) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final texto = renomado.renoTexto;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: RenomadoView.icone(
                RenomadoView.iconeRenomado,
                Icons.star_outline,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(renomado.renoNome, style: textTheme.titleMedium),
                  if (texto != null) ...[
                    const SizedBox(height: 4),
                    Text(texto, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(List<RenomadoModel> renomados, AppLocalizations strings) {
    final command = _vm.listarCommand;
    return Column(
      children: [
        if (command.running) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: renomados.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: _vazio(strings)),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: renomados.length,
                    itemBuilder: (context, index) => _renomado(renomados[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.listarCommand;
    final renomados = _vm.renomados;

    final Widget body;
    if (renomados == null && command.running) {
      body = const Loading();
    } else if (renomados == null) {
      body = _erroCarregamento(strings);
    } else {
      body = _lista(renomados, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('renomados')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: command.running ? null : command.execute,
            icon: RenomadoView.icone(RenomadoView.iconeAtualizar, Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, child) => _screen());
  }
}
