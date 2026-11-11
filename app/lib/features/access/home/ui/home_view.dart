import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../config/app_config.dart';
import '../../../../../config/dialog_sheet.dart';
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

  /// Viewmodel do card de funcionalidades exibido no corpo da home.
  final FuncionalidadeViewmodel funcionalidadeViewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Posição do item de login na [NavigationBar], à direita de tema e idioma.
  static const _loginIndex = 2;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('home')),
        elevation: 0,
        actions: const [OrientationButton(), ThemeModeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [FuncionalidadeView(viewModel: widget.funcionalidadeViewModel)],
      ),
      // Tema, idioma e login são atalhos: nenhum item fica selecionado, então todos usam a mesma cor
      // (sem a pílula e sem a troca de cor do item selecionado).
      bottomNavigationBar: NavigationBarTheme(
        data: _atalhosTheme(context),
        child: NavigationBar(
          indicatorColor: Colors.transparent,
          onDestinationSelected: (index) {
            if (index == _loginIndex) {
              context.push(Routes.login);
              return;
            }
            _showSetting(index);
          },
          destinations: [
            NavigationDestination(icon: Icon(Icons.palette_outlined), label: strings.translate('tema')),
            NavigationDestination(icon: Icon(Icons.language), label: strings.translate('idioma')),
            // Login em destaque: borda e ícone na cor primária.
            NavigationDestination(icon: _loginIcon(context), label: strings.translate('login')),
          ],
        ),
      ),
    );
  }

  /// Mesma cor de ícone e texto em qualquer estado (a do item não selecionado do Material 3).
  NavigationBarThemeData _atalhosTheme(BuildContext context) {
    final theme = Theme.of(context);
    final cor = theme.colorScheme.onSurfaceVariant;
    return NavigationBarTheme.of(context).copyWith(
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: cor)),
      labelTextStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium?.copyWith(color: cor)),
    );
  }

  Widget _loginIcon(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: primary, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.login, color: primary),
    );
  }

  void _showSetting(int index) {
    final strings = AppLocalizations.of(context);
    final title = switch (index) {
      0 => strings.translate('tema'),
      _ => strings.translate('idioma'),
    };

    DialogSheet.show<void>(
      context,
      titulo: title,
      conteudo: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: index == 0 ? _themeControl(context) : _localeControl(context),
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
