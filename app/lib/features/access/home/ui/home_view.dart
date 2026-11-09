import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../config/app_config.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../routing/routes.dart';
import '../widgets/funcionalidade/ui/funcionalidade_view.dart';
import '../widgets/funcionalidade/ui/funcionalidade_viewmodel.dart';
import 'home_viewmodel.dart';

import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.viewModel, required this.funcionalidadeViewModel});

  final HomeViewmodel viewModel;

  /// Viewmodel do card de funcionalidades exibido no corpo da home, acima do botão de login.
  final FuncionalidadeViewmodel funcionalidadeViewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedSetting = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('home')),
        elevation: 0,
        actions: const [OrientationButton(), ThemeModeButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [FuncionalidadeView(viewModel: widget.funcionalidadeViewModel)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  context.push(Routes.login);
                },
                child: Text(strings.translate('login')),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSetting,
        onDestinationSelected: (index) {
          setState(() => _selectedSetting = index);
          _showSetting(index);
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.palette_outlined), label: strings.translate('tema')),
          NavigationDestination(icon: Icon(Icons.language), label: strings.translate('idioma')),
        ],
      ),
    );
  }

  void _showSetting(int index) {
    final strings = AppLocalizations.of(context);
    final title = switch (index) {
      0 => strings.translate('tema'),
      _ => strings.translate('idioma'),
    };

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (index == 0) _themeControl(context),
            if (index == 1) _localeControl(context),
          ],
        ),
      ),
    );
  }

  Widget _themeControl(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SegmentedButton<ThemeMode>(
      expandedInsets: EdgeInsets.zero,
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text(strings.translate('sistema')),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text(strings.translate('claro')),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text(strings.translate('escuro')),
        ),
      ],
      selected: {context.watch<AppConfig>().mode},
      onSelectionChanged: (selection) {
        context.read<AppConfig>().setMode(selection.first);
      },
    );
  }

  Widget _localeControl(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DropdownButtonFormField<Locale?>(
      initialValue: context.watch<AppConfig>().locale,
      decoration: InputDecoration(labelText: strings.translate('idioma')),
      items: [
        DropdownMenuItem(value: null, child: Text(strings.translate('sistema'))),
        DropdownMenuItem(value: Locale('pt', 'BR'), child: Text('Português')),
        DropdownMenuItem(value: Locale('es', 'ES'), child: Text('Español')),
        DropdownMenuItem(value: Locale('en', 'US'), child: Text('English')),
      ],
      onChanged: context.read<AppConfig>().setLocale,
    );
  }
}
