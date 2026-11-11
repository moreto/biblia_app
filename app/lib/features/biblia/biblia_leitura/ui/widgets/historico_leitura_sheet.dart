import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../biblia_leitura_view.dart';
import '../biblia_leitura_viewmodel.dart';

/// Lista do que foi lido na versão (`/v1/versiculo-reacao/lidos/:versaId`), do mais recente para o mais antigo.
/// Tocar um capítulo fecha a lista e abre o capítulo para leitura. Aberta no `DialogBottomSheet` ([show]).
class HistoricoLeituraSheet extends StatelessWidget {
  const HistoricoLeituraSheet({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  /// Fração da altura da tela que a lista ocupa no máximo.
  static const alturaLista = 0.6;

  static Future<void> show(BuildContext context, {required BibliaLeituraViewmodel viewModel}) => DialogSheet.show<void>(
    context,
    titulo: AppLocalizations.of(context).translate('historicoLeitura'),
    conteudo: HistoricoLeituraSheet(viewModel: viewModel),
  );

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

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$completos ${strings.translate('capitulosLidos')} · ${viewModel.versao?.versaCodigo ?? ''}'),
            const Divider(),
            if (historico.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text(strings.translate('nenhumaLeituraRegistrada'))),
              )
            else
              // Altura limitada: a lista rola dentro da folha e só monta os itens visíveis.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * alturaLista),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: historico.length,
                  itemBuilder: (context, index) {
                    final lido = historico[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
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
                        viewModel.abrirCapituloCommand.execute((livrId: lido.livrId, capiNumero: lido.capiNumero));
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
