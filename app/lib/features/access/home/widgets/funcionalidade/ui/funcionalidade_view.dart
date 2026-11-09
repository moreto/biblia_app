import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../../../data/model/funcionalidade/funcionalidade_model.dart';
import 'funcionalidade_viewmodel.dart';

/// Widget da home: card com as funcionalidades do app (`GET /v1/funcionalidade`).
///
/// - Carregando: indicador de progresso dentro do card.
/// - Com a lista: ícone, nome e descrição de cada funcionalidade; as inativas aparecem esmaecidas e com
///   o selo "Em breve".
/// - Erro: mensagem traduzida e "Tentar novamente".
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeCard], [iconeTentarNovamente] e o `funcIcone` de cada item
/// (com [Icons.extension_outlined] se a chave não estiver mapeada).
class FuncionalidadeView extends StatefulWidget {
  const FuncionalidadeView({super.key, required this.viewModel});

  final FuncionalidadeViewmodel viewModel;

  /// Chave do ícone do cabeçalho do card.
  static const iconeCard = 'apps';

  /// Chave do ícone do botão "Tentar novamente".
  static const iconeTentarNovamente = 'refresh';

  @override
  State<FuncionalidadeView> createState() => _FuncionalidadeViewState();
}

class _FuncionalidadeViewState extends State<FuncionalidadeView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.listarCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant FuncionalidadeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.listarCommand.removeListener(_onResult);
    widget.viewModel.listarCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    widget.viewModel.listarCommand.removeListener(_onResult);
    super.dispose();
  }

  /// Só o erro de um recarregamento (com a lista já exibida) gera SnackBar; o erro do primeiro
  /// carregamento aparece dentro do card, em [_erro].
  void _onResult() {
    final command = widget.viewModel.listarCommand;
    if (command.error && widget.viewModel.funcionalidades != null) {
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
    final command = widget.viewModel.listarCommand;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(strings.translate(_mensagemErro(command.result)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: command.running ? null : command.execute,
            icon: _icone(FuncionalidadeView.iconeTentarNovamente, Icons.refresh),
            label: Text(strings.translate('tentarNovamente')),
          ),
        ],
      ),
    );
  }

  /// Mesmo visual do círculo de livro da leitura: preenchido quando ativa, contornado quando não.
  Widget _avatar(FuncionalidadeModel funcionalidade) {
    final scheme = Theme.of(context).colorScheme;
    final ativo = funcionalidade.funcAtivo;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ativo ? scheme.secondaryContainer : Colors.transparent,
        border: ativo ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: _icone(
        funcionalidade.funcIcone,
        Icons.extension_outlined,
        size: 20,
        color: ativo ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _item(FuncionalidadeModel funcionalidade, AppLocalizations strings) {
    final theme = Theme.of(context);
    final ativo = funcionalidade.funcAtivo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(funcionalidade),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        funcionalidade.funcNome,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ativo ? null : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (!ativo)
                      Chip(
                        label: Text(strings.translate('emBreve')),
                        labelStyle: theme.textTheme.labelSmall,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                if (funcionalidade.funcDescricao.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    funcionalidade.funcDescricao,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(List<FuncionalidadeModel> funcionalidades, AppLocalizations strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final funcionalidade in funcionalidades) _item(funcionalidade, strings)],
    );
  }

  Widget _card() {
    final strings = AppLocalizations.of(context);
    final viewModel = widget.viewModel;
    final funcionalidades = viewModel.funcionalidades;

    final Widget corpo;
    if (funcionalidades != null) {
      corpo = _conteudo(funcionalidades, strings);
    } else if (viewModel.listarCommand.error) {
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
                _icone(FuncionalidadeView.iconeCard, Icons.apps, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.translate('funcionalidades'), style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
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
