import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../data/model/menu/menu_model.dart';
import '../widgets/musica/ui/musica_view.dart';
import '../widgets/musica/ui/musica_viewmodel.dart';
import '../widgets/oracao/ui/oracao_view.dart';
import '../widgets/oracao/ui/oracao_viewmodel.dart';
import '../widgets/versiculo/ui/versiculo_view.dart';
import '../widgets/versiculo/ui/versiculo_viewmodel.dart';
import 'dashboard_viewmodel.dart';

import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.viewModel,
    required this.oracaoViewModel,
    required this.versiculoViewModel,
    required this.musicaViewModel,
  });

  final DashboardViewmodel viewModel;

  /// Viewmodel do card de oração exibido no topo da dashboard.
  final OracaoViewmodel oracaoViewModel;

  /// Viewmodel do card de versículo aleatório exibido na dashboard, abaixo do card de oração.
  final VersiculoViewmodel versiculoViewModel;

  /// Viewmodel do card de música aleatória exibido na dashboard, logo abaixo do card de versículo.
  final MusicaViewmodel musicaViewModel;

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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  parent.menuNome,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
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
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: AppLocalizations.of(context).translate('sair'),
            onPressed: () => context.push(Routes.loggof),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OracaoView(viewModel: widget.oracaoViewModel),
          const SizedBox(height: 16),
          VersiculoView(viewModel: widget.versiculoViewModel),
          const SizedBox(height: 16),
          MusicaView(viewModel: widget.musicaViewModel),
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
      width: 120,
      child: Card(
        // Um tom acima do fundo do bottom sheet (surfaceContainerLow).
        color: Theme.of(context).colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mesma cor dos ícones do NavigationBar (padrão M3 para itens não selecionados).
                IconTheme.merge(
                  data: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  child: icon,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
