import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../biblia_leitura_view.dart';
import '../biblia_leitura_viewmodel.dart';

/// Lista do que foi lido na versão (`/v1/versiculo-reacao/lidos/:versaId`), do mais recente para o mais antigo.
/// Tocar um capítulo fecha a lista e abre o capítulo para leitura.
class HistoricoLeituraSheet extends StatelessWidget {
  const HistoricoLeituraSheet({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  String _data(BuildContext context, DateTime? data) =>
      data == null ? '' : ' · ${MaterialLocalizations.of(context).formatMediumDate(data.toLocal())}';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final historico = viewModel.historico;
        final completos = historico.where((c) => c.completo).length;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(strings.translate('historicoLeitura'), style: Theme.of(context).textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$completos ${strings.translate('capitulosLidos')} · ${viewModel.versao?.versaCodigo ?? ''}',
                ),
              ),
              const Divider(),
              Expanded(
                child: historico.isEmpty
                    ? Center(child: Text(strings.translate('nenhumaLeituraRegistrada')))
                    : ListView.builder(
                        controller: controller,
                        itemCount: historico.length,
                        itemBuilder: (context, index) {
                          final lido = historico[index];
                          return ListTile(
                            leading: BibliaLeituraView.icone(
                              lido.completo ? BibliaLeituraView.iconeLido : BibliaLeituraView.iconeParcial,
                              lido.completo ? Icons.check_circle : Icons.timelapse,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text('${lido.livrNome} ${lido.capiNumero}'),
                            subtitle: Text(
                              '${lido.versLidos}/${lido.versTotal} ${strings.translate('versiculosLidos')}'
                              '${_data(context, lido.lidoEm)}',
                            ),
                            trailing: BibliaLeituraView.icone(BibliaLeituraView.iconeProximo, Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).pop();
                              viewModel.abrirCapituloCommand.execute((
                                livrId: lido.livrId,
                                capiNumero: lido.capiNumero,
                              ));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
