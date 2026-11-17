import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'home_viewmodel.dart';

/// Tela de entrada: menu hambúrguer (Drawer) na AppBar e, no corpo, o botão "Bíblia" com o id do aparelho embaixo.
class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.viewModel});

  final HomeViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      // Com `drawer`, a AppBar mostra o ícone do menu hambúrguer sozinha.
      appBar: AppBar(title: Text(strings.translate('home')), actions: const [OrientationButton(), ThemeModeButton()]),
      drawer: const _HomeDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => context.push(Routes.bibliaLeitura),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(strings.translate('biblia')),
              ),
              const SizedBox(height: AppSpacing.md),
              ListenableBuilder(
                listenable: viewModel.idDispositivoCommand,
                builder: (context, _) => _IdDispositivo(viewModel: viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Id do aparelho (Android ID / `identifierForVendor`), selecionável para poder copiar.
class _IdDispositivo extends StatelessWidget {
  const _IdDispositivo({required this.viewModel});

  final HomeViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    if (viewModel.idDispositivoCommand.running) {
      return const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }

    final id = viewModel.idDispositivo;
    if (id == null) {
      return Text(AppLocalizations.of(context).translate('dispositivoNaoIdentificado'), style: estilo);
    }
    return SelectableText(id, style: estilo, textAlign: TextAlign.center);
  }
}

/// Menu lateral da tela de entrada.
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Text(strings.translate('menus'), style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(strings.translate('homeAntiga')),
              onTap: () {
                // Fecha o menu antes de abrir a tela, para ele não ficar aberto ao voltar.
                Navigator.pop(context);
                context.push(Routes.homeOld);
              },
            ),
          ],
        ),
      ),
    );
  }
}
