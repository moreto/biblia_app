import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../data/model/comunidade/comunidade_model.dart';
import '../comunidade_endereco/ui/comunidade_endereco_view.dart';
import '../../../data/model/comunidade/comunidade_endereco_model.dart';
import '../comunidade_endereco/ui/comunidade_endereco_viewmodel.dart';
import '../comunidade_endereco/ui/widgets/comunidade_endereco_form_dialog.dart';
import '../use_case/comunidade_usecase.dart';
import 'comunidade_viewmodel.dart';
import 'widgets/comunidade_form_dialog.dart';
import 'widgets/minhas_comunidades_tab.dart';

/// Comunidades, em abas ([ComunidadeAba]):
/// - "Minhas comunidades" ([MinhasComunidadesTab]): comunidades cadastradas pelo usuário
///   (`/v1/comunidade/usuario/:usuaId`), com tipo e denominação (`/v1/comunidade-tipo` e
///   `/v1/comunidade-denominacao`).
/// - "Endereços" ([ComunidadeEnderecoView]): endereços da comunidade selecionada no topo da aba
///   (`/v1/comunidade-endereco`), carregados na primeira vez que a aba é aberta e de novo depois que as comunidades
///   mudam. "Endereços" no menu de uma comunidade abre a aba com ela selecionada.
///
/// AppBar: tema, orientação e atualizar (recarrega a aba aberta). Erro numa atualização aparece em SnackBar e
/// mantém a lista; o do primeiro carregamento fica na aba.
///
/// Cadastro (`POST`, `PUT` e `DELETE /v1/comunidade`): o botão "Nova comunidade", na parte inferior (na aba
/// "Minhas comunidades"), abre o [ComunidadeFormDialog]; tocar no card ou "Editar" no menu dele abre o mesmo
/// formulário preenchido; "Excluir" pede confirmação. Sucesso mostra SnackBar e recarrega a lista; erro abre o
/// aviso de erro. Na aba "Endereços", o botão inferior vira "Novo endereço" (endereço da comunidade selecionada,
/// [ComunidadeEnderecoFormDialog]) e editar/excluir funcionam do mesmo jeito (`/v1/comunidade-endereco`).
///
/// Para uma nova aba: valor em [ComunidadeAba], comando no viewmodel, widget em `widgets/` e casos em
/// [_conteudo] e [_comandoDa].
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeComunidade], [iconeAtualizar], [iconeAdicionar], [iconeAcoes],
/// [iconeEditar], [iconeExcluir] e o [ComunidadeAba.icone] de cada aba.
class ComunidadeView extends StatefulWidget {
  const ComunidadeView({super.key, required this.viewModel, required this.enderecoViewModel});

  final ComunidadeViewmodel viewModel;

  /// Aba "Endereços".
  final ComunidadeEnderecoViewmodel enderecoViewModel;

  /// Ícone de cada comunidade e da lista vazia.
  static const iconeComunidade = 'church';
  static const iconeAtualizar = 'refresh';
  static const iconeAdicionar = 'plus';
  static const iconeAcoes = 'dots-vertical';
  static const iconeEditar = 'pencil-outline';
  static const iconeExcluir = 'delete-outline';

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
  ComunidadeEnderecoViewmodel get _enderecoVm => widget.enderecoViewModel;

  late final TabController _tabs = TabController(length: _vm.abas.length, vsync: this);

  /// Comandos das abas; o erro de uma atualização vira SnackBar.
  List<Command> _comandos(ComunidadeView view) => [
    view.viewModel.minhasCommand,
    view.viewModel.salvarCommand,
    view.viewModel.excluirCommand,
    view.enderecoViewModel.carregarCommand,
    view.enderecoViewModel.selecionarCommand,
    view.enderecoViewModel.salvarCommand,
    view.enderecoViewModel.excluirCommand,
  ];

  @override
  void initState() {
    super.initState();
    for (final command in _comandos(widget)) {
      command.addListener(_onResult);
    }
    _tabs.addListener(_onAba);
    _onAba();
  }

  @override
  void didUpdateWidget(covariant ComunidadeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final command in _comandos(oldWidget)) {
      command.removeListener(_onResult);
    }
    for (final command in _comandos(widget)) {
      command.addListener(_onResult);
    }
  }

  @override
  void dispose() {
    for (final command in _comandos(widget)) {
      command.removeListener(_onResult);
    }
    _tabs
      ..removeListener(_onAba)
      ..dispose();
    super.dispose();
  }

  /// Abas com carregamento sob demanda carregam ao serem abertas.
  void _onAba() {
    if (_vm.abas[_tabs.index] == ComunidadeAba.enderecos) _enderecoVm.abrir();
  }

  void _onResult() {
    if (!mounted) return;

    // Atualização da lista: só o erro com lista já carregada vira SnackBar; o do primeiro carregamento fica na aba.
    final minhas = _vm.minhasCommand;
    if (minhas.error && _vm.minhas != null) {
      final mensagem = ComunidadeView.mensagemErro(minhas.result);
      minhas.clearResult();
      _mostrarMensagem(mensagem);
    }

    // Atualização dos endereços e troca de comunidade: mesma regra.
    for (final command in [_enderecoVm.carregarCommand, _enderecoVm.selecionarCommand]) {
      if (command.error && _enderecoVm.comunidades != null) {
        final mensagem = ComunidadeView.mensagemErro(command.result);
        command.clearResult();
        _mostrarMensagem(mensagem);
      }
    }

    // Gravação e exclusão (comunidades e endereços): sucesso em SnackBar, erro no aviso de erro. Mudança nas
    // comunidades faz a aba "Endereços" recarregar na próxima abertura.
    for (final (command, sucesso, comunidade) in [
      (_vm.salvarCommand, 'registroSalvo', true),
      (_vm.excluirCommand, 'registroExcluido', true),
      (_enderecoVm.salvarCommand, 'registroSalvo', false),
      (_enderecoVm.excluirCommand, 'registroExcluido', false),
    ]) {
      if (command.error) {
        final mensagem = ComunidadeView.mensagemErro(command.result);
        command.clearResult();
        _mostrarErro(mensagem);
      } else if (command.completed) {
        command.clearResult();
        if (comunidade) _enderecoVm.invalidar();
        _mostrarMensagem(sucesso);
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  void _mostrarErro(String mensagem) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('error'),
        titleButtonPrimary: strings.translate('ok'),
        titleButtonSecondary: strings.translate('ok'),
        isDismissible: false,
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        description: strings.translate(mensagem),
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () => Navigator.of(context).pop(),
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  // ações

  Future<void> _editar([ComunidadeModel? comunidade]) async {
    final result = await ComunidadeFormDialog.show(
      context,
      tipos: _vm.tipos,
      denominacoes: _vm.denominacoes,
      validar: _vm.validar,
      nomeMax: _vm.nomeMax,
      comunidade: comunidade,
    );
    if (result != null) _vm.salvarCommand.execute(result);
  }

  void _excluir(ComunidadeModel comunidade) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('confirmarExclusao'),
        description: '${comunidade.comuNome}\n\n${strings.translate('confirmarExclusaoComunidade')}',
        titleButtonPrimary: strings.translate('excluir'),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          Navigator.of(context).pop();
          _vm.excluirCommand.execute(comunidade);
        },
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  /// Abre a aba "Endereços" com a [comunidade] selecionada.
  void _verEnderecos(ComunidadeModel comunidade) {
    final comuId = comunidade.comuId;
    if (comuId == null) return;
    _enderecoVm.selecionar(comuId);
    _tabs.animateTo(_vm.abas.indexOf(ComunidadeAba.enderecos));
  }

  /// Inclui (sem [endereco]) ou altera endereço da comunidade selecionada na aba "Endereços".
  Future<void> _editarEndereco([ComunidadeEnderecoModel? endereco]) async {
    final comunidade = _enderecoVm.selecionada?.comunidade;
    final comuId = endereco?.comuId ?? comunidade?.comuId;
    if (comuId == null) return;
    final result = await ComunidadeEnderecoFormDialog.show(
      context,
      comuId: comuId,
      comunidadeNome: comunidade?.comuNome ?? '',
      estados: _enderecoVm.estados,
      municipios: _enderecoVm.municipios,
      validar: _enderecoVm.validar,
      limites: _enderecoVm.limites,
      endereco: endereco,
    );
    if (result != null) _enderecoVm.salvarCommand.execute(result);
  }

  void _excluirEndereco(ComunidadeEnderecoModel endereco) {
    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('confirmarExclusao'),
        description: '${_enderecoVm.linhaPrincipal(endereco)}\n\n${strings.translate('confirmarExclusaoEndereco')}',
        titleButtonPrimary: strings.translate('excluir'),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          Navigator.of(context).pop();
          _enderecoVm.excluirCommand.execute(endereco);
        },
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  // layout

  /// Botão inferior da aba aberta: "Nova comunidade" ou "Novo endereço".
  ViewBottomAction _botaoAdicionar(ComunidadeAba aba, AppLocalizations strings) {
    final icone = IconsMap.mdiIcons[ComunidadeView.iconeAdicionar] ?? Icons.add;
    return switch (aba) {
      ComunidadeAba.minhas => ViewBottomAction(
        text: strings.translate('novaComunidade'),
        icon: icone,
        isEnabled: _vm.minhas != null && !_vm.gravando,
        onPressed: () => _editar(),
      ),
      ComunidadeAba.enderecos => ViewBottomAction(
        text: strings.translate('novoEndereco'),
        icon: icone,
        isEnabled: _enderecoVm.selecionada != null && !_enderecoVm.ocupado,
        onPressed: () => _editarEndereco(),
      ),
    };
  }

  Command0 _comandoDa(ComunidadeAba aba) => switch (aba) {
    ComunidadeAba.minhas => _vm.minhasCommand,
    ComunidadeAba.enderecos => _enderecoVm.carregarCommand,
  };

  Widget _conteudo(ComunidadeAba aba) => switch (aba) {
    ComunidadeAba.minhas => MinhasComunidadesTab(
      viewModel: _vm,
      onEditar: _editar,
      onExcluir: _excluir,
      onEnderecos: _verEnderecos,
    ),
    ComunidadeAba.enderecos => ComunidadeEnderecoView(
      viewModel: _enderecoVm,
      onEditar: _editarEndereco,
      onExcluir: _excluirEndereco,
    ),
  };

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final abas = _vm.abas;
    final aba = abas[_tabs.index];
    final atual = _comandoDa(aba);

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
        optionButton2: _botaoAdicionar(aba, strings),
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _enderecoVm, _tabs]),
      builder: (context, child) => _screen(),
    );
  }
}
