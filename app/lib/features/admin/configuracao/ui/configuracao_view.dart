import 'package:app/config/command.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../../data/model/configuracao/configuracao_model.dart';
import 'configuracao_viewmodel.dart';
import 'widgets/configuracao_form_dialog.dart';
import 'widgets/configuracao_item_form_dialog.dart';

import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';

class ConfiguracaoView extends StatefulWidget {
  const ConfiguracaoView({super.key, required this.viewModel});

  final ConfiguracaoViewmodel viewModel;

  @override
  State<ConfiguracaoView> createState() => _ConfiguracaoViewState();
}

class _ConfiguracaoViewState extends State<ConfiguracaoView> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this)..addListener(_onTabChanged);

  /// Comando -> chave da mensagem exibida no sucesso (null = sem mensagem).
  Map<Command, String?> _commandsOf(ConfiguracaoViewmodel viewModel) => {
    viewModel.getConfiguracoesCommand: null,
    viewModel.saveConfiguracaoCommand: 'registroSalvo',
    viewModel.deleteConfiguracaoCommand: 'registroExcluido',
    viewModel.getItensCommand: null,
    viewModel.saveItemCommand: 'registroSalvo',
    viewModel.deleteItemCommand: 'registroExcluido',
  };

  final Map<Command, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _addListeners(widget.viewModel);
  }

  @override
  void didUpdateWidget(covariant ConfiguracaoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _removeListeners();
      _addListeners(widget.viewModel);
    }
  }

  @override
  void dispose() {
    _removeListeners();
    _tabController.dispose();
    super.dispose();
  }

  void _addListeners(ConfiguracaoViewmodel viewModel) {
    _commandsOf(viewModel).forEach((command, successMessage) {
      void listener() => _onResult(command, successMessage);
      _listeners[command] = listener;
      command.addListener(listener);
    });
  }

  void _removeListeners() {
    _listeners.forEach((command, listener) => command.removeListener(listener));
    _listeners.clear();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  void _onResult(Command command, String? successMessage) {
    if (!mounted) return;

    if (command.error) {
      _showError(command.result);
      command.clearResult();
    } else if (command.completed) {
      if (successMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(successMessage))));
      }
      command.clearResult();
    }
  }

  void _showError(Result? commandResult) {
    String msgError = kDefaultAppError;

    if (commandResult case Error(error: final exception)) {
      if (exception is HandledException) {
        msgError = exception.message;
      } else if (exception is HttpServiceException) {
        msgError = exception.message ?? exception.toString();
      } else {
        msgError = exception.toString();
      }
    }

    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: AppLocalizations.of(context).translate('error'),
        titleButtonPrimary: AppLocalizations.of(context).translate('ok'),
        titleButtonSecondary: AppLocalizations.of(context).translate('ok'),
        isDismissible: false,
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        description: AppLocalizations.of(context).translate(msgError),
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () => context.pop(),
        onPressedSecondary: () => context.pop(),
      ),
    ).showModal(context);
  }

  void _confirmDelete({required String description, required VoidCallback onConfirm}) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('confirmarExclusao'),
        description: description,
        titleButtonPrimary: strings.translate('excluir'),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          context.pop();
          onConfirm();
        },
        onPressedSecondary: () => context.pop(),
      ),
    ).showModal(context);
  }

  // ações - configuracao

  Future<void> _editConfiguracao([ConfiguracaoModel? configuracao]) async {
    final result = await ConfiguracaoFormDialog.show(context, configuracao: configuracao);
    if (result != null) widget.viewModel.saveConfiguracaoCommand.execute(result);
  }

  void _deleteConfiguracao(ConfiguracaoModel configuracao) {
    final strings = AppLocalizations.of(context);
    _confirmDelete(
      description: '${configuracao.confNome}\n\n${strings.translate('confirmarExclusaoConfiguracao')}',
      onConfirm: () => widget.viewModel.deleteConfiguracaoCommand.execute(configuracao),
    );
  }

  // ações - configuracao-item

  Future<void> _editItem([ConfiguracaoItemModel? item]) async {
    final confId = widget.viewModel.selectedConfId;
    final configuracoes = widget.viewModel.configuracoes;
    if (confId == null || configuracoes == null) return;

    final result = await ConfiguracaoItemFormDialog.show(
      context,
      configuracoes: configuracoes,
      confId: confId,
      item: item,
    );
    if (result != null) widget.viewModel.saveItemCommand.execute(result);
  }

  void _deleteItem(ConfiguracaoItemModel item) {
    final strings = AppLocalizations.of(context);
    _confirmDelete(
      description: '${item.citeCampo} · ${item.citeValor ?? ''}\n\n${strings.translate('confirmarExclusaoItem')}',
      onConfirm: () => widget.viewModel.deleteItemCommand.execute(item),
    );
  }

  // layout

  bool get _saving =>
      widget.viewModel.saveConfiguracaoCommand.running ||
      widget.viewModel.deleteConfiguracaoCommand.running ||
      widget.viewModel.saveItemCommand.running ||
      widget.viewModel.deleteItemCommand.running;

  Widget _ativoIndicator(bool ativo) {
    final strings = AppLocalizations.of(context);
    return Tooltip(
      message: strings.translate(ativo ? 'ativo' : 'inativo'),
      child: Icon(
        ativo ? Icons.check_circle_outline : Icons.block,
        color: ativo ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
      ),
    );
  }

  Widget _emptyOrError({required String message, VoidCallback? onRetry}) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.translate(message), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _configuracoesTab() {
    final strings = AppLocalizations.of(context);
    final command = widget.viewModel.getConfiguracoesCommand;
    final configuracoes = widget.viewModel.configuracoes;

    if (configuracoes == null) {
      if (command.running) return Center(child: Loading());
      return _emptyOrError(message: 'falhaCarregarConfiguracoes', onRetry: command.execute);
    }
    if (configuracoes.isEmpty) {
      return _emptyOrError(message: 'nenhumaConfiguracaoEncontrada');
    }

    return RefreshIndicator(
      onRefresh: command.execute,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
        itemCount: configuracoes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final configuracao = configuracoes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: _ativoIndicator(configuracao.confAtivo),
              title: Text(configuracao.confNome),
              subtitle: Text(
                '${strings.translate('codigo')}: ${configuracao.confId}'
                '${configuracao.confTipo == null ? '' : ' · ${strings.translate('tipo')}: ${configuracao.confTipo}'}',
              ),
              onTap: _saving ? null : () => _editConfiguracao(configuracao),
              trailing: IconButton(
                tooltip: strings.translate('excluir'),
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : () => _deleteConfiguracao(configuracao),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _itensTab() {
    final strings = AppLocalizations.of(context);
    final configuracoes = widget.viewModel.configuracoes;
    final selectedConfId = widget.viewModel.selectedConfId;
    final command = widget.viewModel.getItensCommand;
    final itens = widget.viewModel.itens;

    if (configuracoes == null) {
      if (widget.viewModel.getConfiguracoesCommand.running) return Center(child: Loading());
      return _emptyOrError(
        message: 'falhaCarregarConfiguracoes',
        onRetry: widget.viewModel.getConfiguracoesCommand.execute,
      );
    }
    if (configuracoes.isEmpty) {
      return _emptyOrError(message: 'nenhumaConfiguracaoEncontrada');
    }

    final Widget content;
    if (selectedConfId == null) {
      content = _emptyOrError(message: 'selecioneConfiguracao');
    } else if (itens == null) {
      content = command.running
          ? Center(child: Loading())
          : _emptyOrError(message: 'falhaCarregarItens', onRetry: widget.viewModel.refreshItens);
    } else if (itens.isEmpty) {
      content = _emptyOrError(message: 'nenhumItemEncontrado');
    } else {
      content = RefreshIndicator(
        onRefresh: widget.viewModel.refreshItens,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
          itemCount: itens.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final item = itens[index];
            final detalhes = [
              item.citeCampo,
              if (item.citeChave != null) '${strings.translate('chave')}: ${item.citeChave}',
              if (item.citeSequencia != null) '${strings.translate('sequencia')}: ${item.citeSequencia}',
            ].join(' · ');
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: _ativoIndicator(item.citeAtivo),
                title: Text(item.citeValor?.isNotEmpty == true ? item.citeValor! : item.citeCampo),
                subtitle: Text(detalhes),
                onTap: _saving ? null : () => _editItem(item),
                trailing: IconButton(
                  tooltip: strings.translate('excluir'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving ? null : () => _deleteItem(item),
                ),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DropdownButtonFormField<int>(
            key: ValueKey(selectedConfId),
            initialValue: selectedConfId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: strings.translate('configuracao'),
              border: const OutlineInputBorder(),
            ),
            items: configuracoes
                .where((configuracao) => configuracao.confId != null)
                .map(
                  (configuracao) => DropdownMenuItem<int>(
                    value: configuracao.confId,
                    child: Text(configuracao.confNome, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: _saving ? null : widget.viewModel.selectConfiguracao,
          ),
        ),
        if (command.running && itens != null) Loading(),
        Expanded(child: content),
      ],
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final isItensTab = _tabController.index == 1;
    final canAdd =
        !_saving && widget.viewModel.configuracoes != null && (!isItensTab || widget.viewModel.selectedConfId != null);

    return Scaffold(
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
      appBar: AppBar(
        title: Text(strings.translate('configuracoes')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: widget.viewModel.getConfiguracoesCommand.running || widget.viewModel.getItensCommand.running
                ? null
                : isItensTab
                ? widget.viewModel.refreshItens
                : widget.viewModel.getConfiguracoesCommand.execute,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: strings.translate('configuracoes')),
            Tab(text: strings.translate('itensConfiguracao')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: strings.translate(isItensTab ? 'novoItemConfiguracao' : 'novaConfiguracao'),
        onPressed: canAdd ? () => isItensTab ? _editItem() : _editConfiguracao() : null,
        child: const Icon(Icons.add),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          if (_saving) Loading(),
          Expanded(
            child: TabBarView(controller: _tabController, children: [_configuracoesTab(), _itensTab()]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ouve também os comandos: o estado running só é liberado depois da última notificação do viewmodel
    return ListenableBuilder(
      listenable: Listenable.merge([widget.viewModel, ..._commandsOf(widget.viewModel).keys]),
      builder: (context, child) => _screen(),
    );
  }
}
