import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../../data/model/versiculo/versiculo_model.dart';
import 'versiculo_viewmodel.dart';

/// Widget da dashboard: card com um versículo sorteado (`GET /v1/versiculo/aleatorio`).
///
/// - Carregando sem versículo: indicador de progresso dentro do card.
/// - Com versículo: referência completa ("João 3:16 (ARC)") como título, texto, testamento e nome da versão, e o botão
///   "Outro versículo", que faz um novo sorteio mantendo o versículo atual visível até a resposta.
/// - Erro sem versículo carregado: mensagem traduzida e "Tentar novamente". Erro em um novo sorteio
///   mantém o versículo atual e mostra um SnackBar.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeCard], [iconeOutro] e [iconeTentarNovamente].
class VersiculoView extends StatefulWidget {
  const VersiculoView({super.key, required this.viewModel});

  final VersiculoViewmodel viewModel;

  /// Chave do ícone do cabeçalho do card.
  static const iconeCard = 'book-open-page-variant';

  /// Chave do ícone do botão "Outro versículo".
  static const iconeOutro = 'autorenew';

  /// Chave do ícone do botão "Tentar novamente".
  static const iconeTentarNovamente = 'refresh';

  @override
  State<VersiculoView> createState() => _VersiculoViewState();
}

class _VersiculoViewState extends State<VersiculoView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.aleatorioCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant VersiculoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.aleatorioCommand.removeListener(_onResult);
    widget.viewModel.aleatorioCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.aleatorioCommand.removeListener(_onResult);
    super.dispose();
  }

  /// Só o erro de um novo sorteio (com versículo já exibido) gera SnackBar; o erro do primeiro
  /// carregamento aparece dentro do card, em [_erro].
  void _onResult() {
    final command = widget.viewModel.aleatorioCommand;
    if (command.error && widget.viewModel.versiculo != null) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(_mensagemErro(command.result)))));
      command.clearResult();
    } else if (command.completed) {
      command.clearResult();
    }
  }

  String _mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  Widget _icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  Widget _carregando() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _erro(AppLocalizations strings) {
    final command = widget.viewModel.aleatorioCommand;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(strings.translate(_mensagemErro(command.result)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: command.running ? null : command.execute,
            icon: _icone(VersiculoView.iconeTentarNovamente, Icons.refresh),
            label: Text(strings.translate('tentarNovamente')),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(VersiculoModel versiculo, AppLocalizations strings) {
    final command = widget.viewModel.aleatorioCommand;
    final theme = Theme.of(context);
    final sorteando = command.running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mesma formatação do card de oração: título em titleMedium e texto em bodyMedium.
        Text(versiculo.versReferencia, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(versiculo.versTexto, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(
          '${versiculo.testNome} · ${versiculo.versaNome}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: sorteando ? null : command.execute,
            icon: sorteando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : _icone(VersiculoView.iconeOutro, Icons.autorenew),
            label: Text(strings.translate('outroVersiculo')),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    final strings = AppLocalizations.of(context);
    final viewModel = widget.viewModel;
    final versiculo = viewModel.versiculo;
    final theme = Theme.of(context);

    final Widget corpo;
    if (versiculo != null) {
      corpo = _conteudo(versiculo, strings);
    } else if (viewModel.aleatorioCommand.error) {
      corpo = _erro(strings);
    } else {
      corpo = _carregando();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _icone(VersiculoView.iconeCard, Icons.menu_book_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.translate('versiculo'), style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 12),
            corpo,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.viewModel, builder: (context, child) => _card());
  }
}
