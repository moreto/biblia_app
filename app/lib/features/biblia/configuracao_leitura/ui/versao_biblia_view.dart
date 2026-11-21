import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../biblia_leitura/ui/biblia_leitura_viewmodel.dart';

/// Escolha da versão da Bíblia (`/versao-biblia`), aberta pelas Configurações de leitura.
///
/// Lista as versões com a sigla e o nome; a atual fica marcada. Tocar em outra troca a versão da leitura (que
/// recarrega o capítulo) e volta.
class VersaoBibliaView extends StatelessWidget {
  const VersaoBibliaView({super.key, required this.leitura});

  final BibliaLeituraViewmodel leitura;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('versaoBiblia'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([leitura, leitura.versaoCommand]),
        builder: (context, _) {
          final atual = leitura.versao?.versaId;
          return Column(
            children: [
              if (leitura.versaoCommand.running) const LinearProgressIndicator(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: leitura.versoes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                  itemBuilder: (context, i) {
                    final versao = leitura.versoes[i];
                    final selecionada = versao.versaId == atual;
                    return ListTile(
                      key: ValueKey('versao_${versao.versaId}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selecionada ? scheme.primary : scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          versao.versaCodigo,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: selecionada ? scheme.onPrimary : scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      title: Text(versao.versaNome),
                      subtitle: Text(versao.versaCodigo),
                      selected: selecionada,
                      trailing: selecionada ? Icon(Icons.check_circle, color: scheme.primary) : null,
                      onTap: leitura.versaoCommand.running
                          ? null
                          : () {
                              if (!selecionada) leitura.versaoCommand.execute(versao);
                              Navigator.of(context).maybePop();
                            },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
