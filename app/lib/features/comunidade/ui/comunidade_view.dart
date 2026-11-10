import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../use_case/comunidade_usecase.dart';
import 'comunidade_viewmodel.dart';
import 'widgets/minhas_comunidades_tab.dart';

/// Comunidades, em abas ([ComunidadeAba]):
/// - "Minhas comunidades" ([MinhasComunidadesTab]): comunidades cadastradas pelo usuário
///   (`/v1/comunidade/usuario/:usuaId`), com tipo e denominação (`/v1/comunidade-tipo` e
///   `/v1/comunidade-denominacao`).
///
/// AppBar: tema, orientação e atualizar (recarrega a aba aberta). Erro numa atualização aparece em SnackBar e
/// mantém a lista; o do primeiro carregamento fica na aba.
///
/// Para uma nova aba: valor em [ComunidadeAba], comando no viewmodel, widget em `widgets/` e casos em
/// [_conteudo] e [_comandoDa].
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeComunidade], [iconeAtualizar] e o [ComunidadeAba.icone] de cada aba.
class ComunidadeView extends StatefulWidget {
  const ComunidadeView({super.key, required this.viewModel});

  final ComunidadeViewmodel viewModel;

  /// Ícone de cada comunidade e da lista vazia.
  static const iconeComunidade = 'church';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  @override
  State<ComunidadeView> createState() => _ComunidadeViewState();
}

class _ComunidadeViewState extends State<ComunidadeView> with SingleTickerProviderStateMixin {
  ComunidadeViewmodel get _vm => widget.viewModel;

  late final TabController _tabs = TabController(length: _vm.abas.length, vsync: this);

  /// Comandos das abas; o erro de uma atualização vira SnackBar.
  List<Command> _comandos(ComunidadeViewmodel vm) => [vm.minhasCommand];

  @override
  void initState() {
    super.initState();
    for (final command in _comandos(_vm)) {
      command.addListener(_onResult);
    }
  }

  @override
  void didUpdateWidget(covariant ComunidadeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final command in _comandos(oldWidget.viewModel)) {
      command.removeListener(_onResult);
    }
    for (final command in _comandos(_vm)) {
      command.addListener(_onResult);
    }
  }

  @override
  void dispose() {
    for (final command in _comandos(_vm)) {
      command.removeListener(_onResult);
    }
    _tabs.dispose();
    super.dispose();
  }

  /// Só erros de atualização (com lista já carregada) viram SnackBar; o do primeiro carregamento fica na aba.
  void _onResult() {
    final command = _vm.minhasCommand;
    if (!command.error || _vm.minhas == null) return;

    final mensagem = ComunidadeView.mensagemErro(command.result);
    command.clearResult();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  Command0 _comandoDa(ComunidadeAba aba) => switch (aba) {
    ComunidadeAba.minhas => _vm.minhasCommand,
  };

  Widget _conteudo(ComunidadeAba aba) => switch (aba) {
    ComunidadeAba.minhas => MinhasComunidadesTab(viewModel: _vm),
  };

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final abas = _vm.abas;
    final atual = _comandoDa(abas[_tabs.index]);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('comunidades')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: atual.running ? null : atual.execute,
            icon: ComunidadeView.icone(ComunidadeView.iconeAtualizar, Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final aba in abas)
              Tab(icon: ComunidadeView.icone(aba.icone, Icons.groups_outlined), text: strings.translate(aba.rotulo)),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: TabBarView(controller: _tabs, children: [for (final aba in abas) _conteudo(aba)]),
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: Listenable.merge([_vm, _tabs]), builder: (context, child) => _screen());
  }
}
