import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../data/model/usuario/usuario_detalhe_model.dart';
import '../use_case/usuario_usecase.dart';
import 'usuario_viewmodel.dart';
import 'widgets/usuario_configuracao_tab.dart';
import 'widgets/usuario_dados_tab.dart';
import 'widgets/usuario_senha_tab.dart';

/// Tela "Meus dados" (`Routes.usuario`): o usuário vê e altera os dados do cadastro inicial, em abas ([UsuarioAba]):
///
/// - "Dados cadastrais" ([UsuarioDadosTab]): cabeçalho com iniciais, nome, `@usuario` e situação da conta; e-mail
///   e identificador só leitura; nome completo e nome de usuário editáveis (`PUT /v1/usuario/usuario-detalhe`).
/// - "Senha" ([UsuarioSenhaTab]): senha atual, nova e confirmação (`PUT /v1/acesso/senha`); os campos são limpos
///   depois da troca.
/// - "Configurações" ([UsuarioConfiguracaoTab]): avisos por e-mail, leitura aberta e quantidade de registros
///   guardados (`/v1/usuario-configuracao`); sem configuração gravada, mostra os valores padrão com um aviso.
///
/// O botão inferior, ao lado de "Voltar", muda com a aba: "Salvar" (habilitado só com alteração), "Alterar senha" e
/// "Salvar". Primeiro carregamento: progresso; se falhar, "Tentar novamente". Depois disso os dados são mantidos;
/// erros de atualização e de gravação viram SnackBar, e gravações concluídas também (`dadosSalvos`, `senhaAlterada`,
/// `configuracoesSalvas`).
///
/// Ícones (em [IconsMap.mdiIcons]): os de [UsuarioAba], [UsuarioConfiguracaoOpcao] e [UsuarioConfiguracaoQuantidade]
/// e as constantes `icone*` desta classe.
class UsuarioView extends StatefulWidget {
  const UsuarioView({super.key, required this.viewModel});

  final UsuarioViewmodel viewModel;

  /// Tela (também `func_icone` de /usuario).
  static const iconeTela = 'account-cog-outline';
  static const iconeEmail = 'email-outline';
  static const iconeIdentificador = 'identifier';
  static const iconeNome = 'account-outline';
  static const iconeUsuario = 'at';
  static const iconeSomenteLeitura = 'lock-outline';
  static const iconeAtivo = 'check-circle';
  static const iconeInativo = 'alert-circle-outline';
  static const iconeSenha = 'lock-outline';
  static const iconeNovaSenha = 'lock-plus-outline';
  static const iconeConfirmacao = 'lock-check-outline';
  static const iconeExibir = 'eye-outline';
  static const iconeOcultar = 'eye-off-outline';
  static const iconeSalvar = 'content-save-outline';
  static const iconeAlterarSenha = 'lock-reset';
  static const iconeDescartar = 'undo';
  static const iconeInformacao = 'information-outline';
  static const iconeAvisosEmail = 'email-fast-outline';
  static const iconeHistorico = 'history';
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
  State<UsuarioView> createState() => _UsuarioViewState();
}

class _UsuarioViewState extends State<UsuarioView> with SingleTickerProviderStateMixin {
  UsuarioViewmodel get _vm => widget.viewModel;

  late final TabController _tabs = TabController(length: _vm.abas.length, vsync: this);
  final _dadosForm = GlobalKey<FormState>();
  final _senhaForm = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  /// Detalhe que está nos campos de nome e usuário; quando o viewmodel troca o detalhe, os campos são refeitos.
  UsuarioDetalheModel? _detalheNosCampos;

  /// Comandos de gravação e a mensagem de sucesso de cada um.
  Map<Command, String> _gravacoes(UsuarioViewmodel vm) => {
    vm.salvarDadosCommand: UsuarioUseCase.kDadosSalvos,
    vm.alterarSenhaCommand: UsuarioUseCase.kSenhaAlterada,
    vm.salvarConfiguracaoCommand: UsuarioUseCase.kConfiguracoesSalvas,
  };

  List<Command> _comandos(UsuarioViewmodel vm) => [vm.carregarCommand, ..._gravacoes(vm).keys];

  @override
  void initState() {
    super.initState();
    for (final c in _comandos(_vm)) {
      c.addListener(_onResult);
    }
    _vm.addListener(_sincronizarCampos);
    _sincronizarCampos();
  }

  @override
  void didUpdateWidget(covariant UsuarioView oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final c in _comandos(oldWidget.viewModel)) {
      c.removeListener(_onResult);
    }
    oldWidget.viewModel.removeListener(_sincronizarCampos);
    for (final c in _comandos(_vm)) {
      c.addListener(_onResult);
    }
    _vm.addListener(_sincronizarCampos);
  }

  @override
  void dispose() {
    for (final c in _comandos(_vm)) {
      c.removeListener(_onResult);
    }
    _vm.removeListener(_sincronizarCampos);
    _tabs.dispose();
    for (final c in [
      _nomeController,
      _usuarioController,
      _senhaAtualController,
      _novaSenhaController,
      _confirmacaoController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sincronizarCampos() {
    final detalhe = _vm.detalhe;
    if (detalhe == null || identical(detalhe, _detalheNosCampos)) return;
    _detalheNosCampos = detalhe;
    _nomeController.text = detalhe.udetNome;
    _usuarioController.text = detalhe.udetUsuario;
  }

  /// Erros de atualização (com dados já carregados) e de gravação, e gravações concluídas, viram SnackBar.
  void _onResult() {
    if (!mounted) return;
    final carregar = _vm.carregarCommand;
    if (carregar.error && _vm.detalhe != null) {
      final mensagem = UsuarioView.mensagemErro(carregar.result);
      carregar.clearResult();
      _mensagem(mensagem);
    }
    for (final MapEntry(key: command, value: sucesso) in _gravacoes(_vm).entries) {
      if (command.error) {
        final mensagem = UsuarioView.mensagemErro(command.result);
        command.clearResult();
        _mensagem(mensagem);
      } else if (command.completed) {
        command.clearResult();
        if (command == _vm.alterarSenhaCommand) _limparSenha();
        _mensagem(sucesso);
      }
    }
  }

  void _limparSenha() {
    _senhaAtualController.clear();
    _novaSenhaController.clear();
    _confirmacaoController.clear();
    _senhaForm.currentState?.reset();
  }

  void _mensagem(String chave) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(chave))));
  }

  void _salvarDados() {
    FocusScope.of(context).unfocus();
    if (!(_dadosForm.currentState?.validate() ?? false)) return;
    _vm.salvarDadosCommand.execute((nome: _nomeController.text, usuario: _usuarioController.text));
  }

  void _alterarSenha() {
    FocusScope.of(context).unfocus();
    if (!(_senhaForm.currentState?.validate() ?? false)) return;
    _vm.alterarSenhaCommand.execute((
      senhaAtual: _senhaAtualController.text,
      novaSenha: _novaSenhaController.text,
      confirmacao: _confirmacaoController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _tabs, _nomeController, _usuarioController]),
      builder: (context, _) => _screen(),
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final carregado = _vm.detalhe != null;

    final Widget body;
    if (!carregado && !command.error) {
      body = const Loading();
    } else if (!carregado) {
      body = _erroCarregamento(strings);
    } else {
      body = Column(
        children: [
          if (_vm.ocupado) const LinearProgressIndicator() else const SizedBox(height: 4),
          Expanded(
            child: TabBarView(controller: _tabs, children: [for (final aba in _vm.abas) _conteudo(aba)]),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('meusDados')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: _vm.ocupado ? null : command.execute,
            icon: UsuarioView.icone(UsuarioView.iconeAtualizar, Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            for (final aba in _vm.abas)
              Tab(icon: UsuarioView.icone(aba.icone, Icons.person_outline), text: strings.translate(aba.rotulo)),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: ViewBottomActions(
        optionButton2: _acao(_vm.abas[_tabs.index], strings, carregado),
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  ViewBottomAction _acao(UsuarioAba aba, AppLocalizations strings, bool carregado) => switch (aba) {
    UsuarioAba.dados => ViewBottomAction(
      text: strings.translate('salvar'),
      icon: IconsMap.mdiIcons[UsuarioView.iconeSalvar] ?? Icons.save_outlined,
      isVisible: carregado,
      isEnabled: !_vm.ocupado && _vm.dadosAlterados(_nomeController.text, _usuarioController.text),
      onPressed: _salvarDados,
    ),
    UsuarioAba.senha => ViewBottomAction(
      text: strings.translate('alterarSenha'),
      icon: IconsMap.mdiIcons[UsuarioView.iconeAlterarSenha] ?? Icons.lock_reset,
      isVisible: carregado,
      isEnabled: !_vm.ocupado,
      onPressed: _alterarSenha,
    ),
    UsuarioAba.configuracoes => ViewBottomAction(
      text: strings.translate('salvar'),
      icon: IconsMap.mdiIcons[UsuarioView.iconeSalvar] ?? Icons.save_outlined,
      isVisible: carregado,
      isEnabled: !_vm.ocupado && _vm.configuracaoAlterada,
      onPressed: _vm.salvarConfiguracaoCommand.execute,
    ),
  };

  Widget _conteudo(UsuarioAba aba) => switch (aba) {
    UsuarioAba.dados => UsuarioDadosTab(
      viewModel: _vm,
      formKey: _dadosForm,
      nomeController: _nomeController,
      usuarioController: _usuarioController,
      onSalvar: _salvarDados,
    ),
    UsuarioAba.senha => UsuarioSenhaTab(
      viewModel: _vm,
      formKey: _senhaForm,
      senhaAtualController: _senhaAtualController,
      novaSenhaController: _novaSenhaController,
      confirmacaoController: _confirmacaoController,
      onAlterar: _alterarSenha,
    ),
    UsuarioAba.configuracoes => UsuarioConfiguracaoTab(viewModel: _vm),
  };

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.carregarCommand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(UsuarioView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: UsuarioView.icone(UsuarioView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }
}
