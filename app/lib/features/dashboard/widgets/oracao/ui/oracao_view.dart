import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../../data/model/oracao/oracao_model.dart';
import 'oracao_viewmodel.dart';

/// Widget da dashboard: card com uma oração sorteada (`GET /v1/oracao/aleatoria`).
///
/// - Carregando sem oração: indicador de progresso dentro do card.
/// - Com oração: nome, texto recolhido em [linhasRecolhido] linhas ("Ler mais" expande) e o botão
///   "Outra oração", que faz um novo sorteio mantendo a oração atual visível até a resposta.
/// - Erro sem oração carregada: mensagem traduzida e "Tentar novamente". Erro em um novo sorteio
///   mantém a oração atual e mostra um SnackBar.
class OracaoView extends StatefulWidget {
  const OracaoView({super.key, required this.viewModel});

  final OracaoViewmodel viewModel;

  /// Linhas do texto exibidas com o card recolhido.
  static const linhasRecolhido = 4;

  @override
  State<OracaoView> createState() => _OracaoViewState();
}

class _OracaoViewState extends State<OracaoView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.aleatoriaCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant OracaoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.aleatoriaCommand.removeListener(_onResult);
    widget.viewModel.aleatoriaCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.aleatoriaCommand.removeListener(_onResult);
    super.dispose();
  }

  /// Só o erro de um novo sorteio (com oração já exibida) gera SnackBar; o erro do primeiro
  /// carregamento aparece dentro do card, em [_erro].
  void _onResult() {
    final command = widget.viewModel.aleatoriaCommand;
    if (command.error && widget.viewModel.oracao != null) {
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

  Widget _carregando() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _erro(AppLocalizations strings) {
    final command = widget.viewModel.aleatoriaCommand;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(strings.translate(_mensagemErro(command.result)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: command.running ? null : command.execute,
            icon: const Icon(Icons.refresh),
            label: Text(strings.translate('tentarNovamente')),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(OracaoModel oracao, AppLocalizations strings) {
    final viewModel = widget.viewModel;
    final theme = Theme.of(context);
    final sorteando = viewModel.aleatoriaCommand.running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(oracao.oracNome, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        // O texto completo é medido para só mostrar "Ler mais" quando ele passa do limite de linhas.
        LayoutBuilder(
          builder: (context, constraints) {
            final style = theme.textTheme.bodyMedium;
            final painter = TextPainter(
              text: TextSpan(text: oracao.oracTexto, style: style),
              maxLines: OracaoView.linhasRecolhido,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            final excede = painter.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  oracao.oracTexto,
                  style: style,
                  maxLines: viewModel.expandida ? null : OracaoView.linhasRecolhido,
                  overflow: viewModel.expandida ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                if (excede)
                  TextButton(
                    onPressed: viewModel.alternarExpandida,
                    child: Text(strings.translate(viewModel.expandida ? 'lerMenos' : 'lerMais')),
                  ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: sorteando ? null : viewModel.aleatoriaCommand.execute,
            icon: sorteando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.autorenew),
            label: Text(strings.translate('outraOracao')),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    final strings = AppLocalizations.of(context);
    final viewModel = widget.viewModel;
    final oracao = viewModel.oracao;

    final Widget corpo;
    if (oracao != null) {
      corpo = _conteudo(oracao, strings);
    } else if (viewModel.aleatoriaCommand.error) {
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
                Icon(Icons.volunteer_activism_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.translate('oracao'), style: Theme.of(context).textTheme.labelLarge),
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
