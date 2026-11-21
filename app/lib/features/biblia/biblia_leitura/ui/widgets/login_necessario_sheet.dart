import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Sheet de baixo para funcionalidades só de quem está logado: explica ([mensagem], chave de tradução) e oferece
/// "Voltar" e "Continuar para o login".
abstract final class LoginNecessarioSheet {
  /// Verdadeiro se o usuário escolheu continuar para o login.
  static Future<bool> perguntar(BuildContext context, {required String titulo, required String mensagem}) async {
    final strings = AppLocalizations.of(context);
    final entrar = await DialogSheet.show<bool>(
      context,
      titulo: titulo,
      conteudo: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(strings.translate(mensagem), style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
          Builder(
            builder: (sheetContext) => DialogSheet.acoes([
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(strings.translate('voltar')),
              ),
              FilledButton(
                key: const ValueKey('continuarLogin'),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(strings.translate('continuarParaLogin')),
              ),
            ]),
          ),
        ],
      ),
    );
    return entrar ?? false;
  }
}
