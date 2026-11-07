import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'loggof_viewmodel.dart';

class LoggofView extends StatelessWidget {
  const LoggofView({super.key, required this.viewModel});

  final LoggofViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('Encerrar sessão'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 56),
              const SizedBox(height: 16),
              Text(
                strings.translate('Deseja sair da aplicação?'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  viewModel.logout();
                  context.go(Routes.home);
                },
                icon: const Icon(Icons.logout),
                label: Text(strings.translate('Sair')),
              ),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.dashboard);
                  }
                },
                child: Text(strings.translate('Cancelar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
