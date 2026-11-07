import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../data/model/menu/menu_model.dart';
import '../../oracao/ui/oracao_view.dart';
import '../../oracao/ui/oracao_viewmodel.dart';
import 'dashboard_viewmodel.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.viewModel, required this.oracaoViewModel});

  final DashboardViewmodel viewModel;

  /// Viewmodel do card de oração exibido no topo da dashboard.
  final OracaoViewmodel oracaoViewModel;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.menuCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.menuCommand.removeListener(_onResult);
    widget.viewModel.menuCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.menuCommand.removeListener(_onResult);
    super.dispose();
  }

  void _onResult() {
    final command = widget.viewModel.menuCommand;
    if (command.error) {
      var message = kDefaultAppError;
      if (command.result case Error(error: final exception)) {
        if (exception is HandledException) {
          message = exception.message;
        } else if (exception is HttpServiceException) {
          message = exception.message ?? exception.toString();
        } else {
          message = exception.toString();
        }
      }

      DialogBottomSheetWarning(
        dialogWarning: DialogWarning(
          title: AppLocalizations.of(context).translate('error'),
          titleButtonPrimary: AppLocalizations.of(context).translate('ok'),
          titleButtonSecondary: AppLocalizations.of(context).translate('ok'),
          isDismissible: false,
          typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
          description: AppLocalizations.of(context).translate(message),
          statusDialog: DialogBottomSheetStatus.statusCritical,
          onPressedPrimary: () => context.pop(),
          onPressedSecondary: () => context.pop(),
        ),
      ).showModal(context);

      command.clearResult();
    } else if (command.completed) {
      command.clearResult();
    }
  }

  void _selectMenu(Menu menu, int index) {
    setState(() => _currentIndex = index);

    final children = menu.children ?? const [];
    if (children.isNotEmpty) {
      _showSubmenu(menu, children);
      return;
    }

    _navigateTo(menu);
  }

  void _showSubmenu(Menu parent, List<Menu> children) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              Text(parent.menuNome),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return QuickCard(
                      title: child.menuNome,
                      icon: _iconFor(child),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _navigateTo(child);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _navigateTo(Menu menu) {
    final route = menu.menuRota;
    if (route == null || route.isEmpty) {
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${strings.translate('rotaNaoDefinida')}: ${menu.menuNome}')));
      return;
    }
    context.push(route);
  }

  Icon _iconFor(Menu menu) {
    final icon = IconsMap.mdiIcons[menu.menuIcone];
    if (icon == null) {
      return const Icon(Icons.error_outline);
    }
    return Icon(icon);
  }

  Widget _buildMenu(MenuModel menuModel) {
    final menus = menuModel.menu;
    if (menus.isEmpty) {
      return Scaffold(body: Center(child: Text(AppLocalizations.of(context).translate('nenhumMenuDisponivel'))));
    }

    final selectedIndex = _currentIndex < menus.length ? _currentIndex : 0;
    final selectedMenu = menus[selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedMenu.menuNome),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).translate('Sair'),
            onPressed: () => context.push(Routes.loggof),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OracaoView(viewModel: widget.oracaoViewModel),
          const SizedBox(height: 32),
          Column(children: [_iconFor(selectedMenu), const SizedBox(height: 20), Text(selectedMenu.menuNome)]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _selectMenu(menus[index], index),
        destinations: [
          for (final menu in menus)
            NavigationDestination(icon: _iconFor(menu), selectedIcon: _iconFor(menu), label: menu.menuNome),
        ],
      ),
    );
  }

  Widget _screen() {
    final menuCommand = widget.viewModel.menuCommand;
    final menuModel = widget.viewModel.menuModel;

    if (menuCommand.running && menuModel == null) {
      return const Loading();
    }

    if (menuModel != null) {
      return _buildMenu(menuModel);
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context).translate('falhaCarregarMenu')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: menuCommand.running ? null : menuCommand.execute,
              child: Text(AppLocalizations.of(context).translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.viewModel, builder: (context, child) => _screen());
  }
}

class QuickCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final VoidCallback onTap;

  const QuickCard({super.key, required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 14),
                Text(title, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
