import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../../data/model/menu/menu_item_model.dart';
import 'menu_viewmodel.dart';
import 'widgets/menu_form_dialog.dart';

import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key, required this.viewModel});

  final MenuViewmodel viewModel;

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  static const double _indentacaoNivel = 28;

  /// Comando -> chave da mensagem exibida no sucesso (null = sem mensagem).
  Map<Command, String?> _commandsOf(MenuViewmodel viewModel) => {
    viewModel.getMenusCommand: null,
    viewModel.saveMenuCommand: 'registroSalvo',
    viewModel.deleteMenuCommand: 'registroExcluido',
  };

  final Map<Command, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _addListeners(widget.viewModel);
  }

  @override
  void didUpdateWidget(covariant MenuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _removeListeners();
      _addListeners(widget.viewModel);
    }
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  void _addListeners(MenuViewmodel viewModel) {
    _commandsOf(viewModel).forEach((command, successMessage) {
      void listener() => _onResult(command, successMessage);
      _listeners[command] = listener;
      command.addListener(listener);
    });
  }

  void _removeListeners() {
    _listeners.forEach((command, listener) => command.removeListener(listener));
    _listeners.clear();
  }

  void _onResult(Command command, String? successMessage) {
    if (!mounted) return;

    if (command.error) {
      _showError(command.result);
      command.clearResult();
    } else if (command.completed) {
      if (successMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(successMessage))));
      }
      command.clearResult();
    }
  }

  void _showError(Result? commandResult) {
    String msgError = kDefaultAppError;

    if (commandResult case Error(error: final exception)) {
      if (exception is HandledException) {
        msgError = exception.message;
      } else if (exception is HttpServiceException) {
        msgError = exception.message ?? exception.toString();
      } else {
        msgError = exception.toString();
      }
    }

    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: AppLocalizations.of(context).translate('error'),
        titleButtonPrimary: AppLocalizations.of(context).translate('ok'),
        titleButtonSecondary: AppLocalizations.of(context).translate('ok'),
        isDismissible: false,
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        description: AppLocalizations.of(context).translate(msgError),
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () => context.pop(),
        onPressedSecondary: () => context.pop(),
      ),
    ).showModal(context);
  }

  // ações

  Future<void> _editMenu({MenuItemModel? menu, int? menuParentId}) async {
    final result = await MenuFormDialog.show(
      context,
      opcoesPai: widget.viewModel.opcoesPai(menu),
      menu: menu,
      menuParentId: menuParentId,
    );
    if (result != null) widget.viewModel.saveMenuCommand.execute(result);
  }

  void _deleteMenu(MenuItemModel menu) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('confirmarExclusao'),
        description: '${menu.menuNome}\n\n${strings.translate('confirmarExclusaoMenu')}',
        titleButtonPrimary: strings.translate('excluir'),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          context.pop();
          widget.viewModel.deleteMenuCommand.execute(menu);
        },
        onPressedSecondary: () => context.pop(),
      ),
    ).showModal(context);
  }

  // layout

  bool get _saving => widget.viewModel.saveMenuCommand.running || widget.viewModel.deleteMenuCommand.running;

  Widget _emptyOrError({required String message, VoidCallback? onRetry}) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.translate(message), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _icone(MenuItemModel menu, {required bool raiz}) {
    final colors = Theme.of(context).colorScheme;
    final icon = IconsMap.mdiIcons[menu.menuIcone];
    return CircleAvatar(
      radius: raiz ? 20 : 16,
      backgroundColor: raiz ? colors.primaryContainer : colors.surfaceContainerHighest,
      foregroundColor: raiz ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      child: Icon(icon ?? Icons.circle_outlined, size: raiz ? 22 : 18),
    );
  }

  /// Conector da árvore: linha vertical do pai com um traço até o item (├ ou └ no último filho).
  Widget _conector({required bool ultimo}) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: _indentacaoNivel,
      child: Stack(
        children: [
          Positioned(
            left: _indentacaoNivel / 2 - 1,
            top: 0,
            bottom: 0,
            child: FractionallySizedBox(
              heightFactor: ultimo ? 0.5 : 1,
              alignment: Alignment.topCenter,
              child: Container(width: 2, color: color),
            ),
          ),
          Positioned(
            left: _indentacaoNivel / 2 - 1,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: Container(height: 2, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _item(MenuNivelModel item, {required bool ultimoFilho}) {
    final strings = AppLocalizations.of(context);
    final menu = item.menu;
    final raiz = item.nivel == 0;
    final recolhido = widget.viewModel.isRecolhido(menu);
    final detalhes = [
      menu.menuChave,
      if (menu.menuRota != null) menu.menuRota!,
      if (menu.menuSequencia != null) '${strings.translate('sequencia')}: ${menu.menuSequencia}',
    ].join(' · ');

    final card = Card(
      margin: EdgeInsets.zero,
      elevation: raiz ? 1 : 0,
      shape: raiz
          ? null
          : RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: !raiz,
        leading: _icone(menu, raiz: raiz),
        title: Text(
          menu.menuNome,
          style: raiz ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) : null,
        ),
        subtitle: Text(detalhes, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: _saving ? null : () => _editMenu(menu: menu),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (raiz)
              IconButton(
                tooltip: strings.translate('novoSubmenu'),
                icon: const Icon(Icons.add),
                onPressed: _saving ? null : () => _editMenu(menuParentId: menu.menuId),
              ),
            if (item.possuiFilhos)
              IconButton(
                tooltip: strings.translate(recolhido ? 'expandir' : 'recolher'),
                icon: Badge.count(
                  count: menu.children.length,
                  child: Icon(recolhido ? Icons.expand_more : Icons.expand_less),
                ),
                onPressed: () => widget.viewModel.alternarRecolhido(menu),
              )
            else
              IconButton(
                tooltip: strings.translate('excluir'),
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : () => _deleteMenu(menu),
              ),
          ],
        ),
      ),
    );

    return Padding(
      // filhos: o conector fica alinhado sob o ícone do pai (margem 16 + padding do ListTile 16 + raio 20 - meio conector)
      padding: EdgeInsets.fromLTRB(raiz ? 16 : 16 + 22 + (item.nivel - 1) * _indentacaoNivel, raiz ? 8 : 0, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!raiz) _conector(ultimo: ultimoFilho),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: raiz ? 0 : 3),
                child: card,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    final command = widget.viewModel.getMenusCommand;
    final menus = widget.viewModel.menusVisiveis;

    if (menus == null) {
      if (command.running) return Center(child: Loading());
      return _emptyOrError(message: 'falhaCarregarMenus', onRetry: command.execute);
    }
    if (menus.isEmpty) {
      return _emptyOrError(message: 'nenhumMenuEncontrado');
    }

    return RefreshIndicator(
      onRefresh: command.execute,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 88),
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final item = menus[index];
          final proximo = index + 1 < menus.length ? menus[index + 1] : null;
          return _item(item, ultimoFilho: proximo == null || proximo.nivel < item.nivel);
        },
      ),
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
      appBar: AppBar(
        title: Text(strings.translate('menus')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: widget.viewModel.getMenusCommand.running ? null : widget.viewModel.getMenusCommand.execute,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: strings.translate('novoMenu'),
        onPressed: !_saving && widget.viewModel.menus != null ? () => _editMenu() : null,
        child: const Icon(Icons.add),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          if (_saving || (widget.viewModel.getMenusCommand.running && widget.viewModel.menus != null)) Loading(),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ouve também os comandos: o estado running só é liberado depois da última notificação do viewmodel
    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, ..._commandsOf(widget.viewModel).keys]),
      builder: (context, child) => _screen(),
    );
  }
}
