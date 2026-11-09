import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/command.dart';
import 'registro_viewmodel.dart';

import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';

/// Cadastro de usuário (`POST /v1/acesso/registro`), aberto pelo link "Criar conta" do login.
///
/// - Dados: e-mail, senha e confirmação. Ao cadastrar, a API envia um código de 6 dígitos ao e-mail.
/// - Ativação: código recebido (`POST /v1/usuario-ativacao/confirmar`). Ativada a conta, volta ao login
///   devolvendo o e-mail cadastrado, para o login já vir preenchido.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeCabecalho], [iconeEmail], [iconeSenha], [iconeConfirmacao],
/// [iconeExibir], [iconeOcultar] e [iconeCodigo].
class RegistroView extends StatefulWidget {
  const RegistroView({super.key, required this.viewModel});

  final RegistroViewmodel viewModel;

  static const iconeCabecalho = 'account-plus-outline';
  static const iconeEmail = 'email-outline';
  static const iconeSenha = 'lock-outline';
  static const iconeConfirmacao = 'lock-check-outline';
  static const iconeExibir = 'eye-outline';
  static const iconeOcultar = 'eye-off-outline';
  static const iconeCodigo = 'shield-check-outline';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  final _codigoController = TextEditingController();
  bool _senhaVisivel = false;

  RegistroViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _addListeners(_vm);
  }

  @override
  void didUpdateWidget(covariant RegistroView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _removeListeners(oldWidget.viewModel);
      _addListeners(widget.viewModel);
    }
  }

  @override
  void dispose() {
    _removeListeners(_vm);
    _emailController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _addListeners(RegistroViewmodel vm) {
    vm.registrarCommand.addListener(_onRegistrarResult);
    vm.ativarCommand.addListener(_onAtivarResult);
  }

  void _removeListeners(RegistroViewmodel vm) {
    vm.registrarCommand.removeListener(_onRegistrarResult);
    vm.ativarCommand.removeListener(_onAtivarResult);
  }

  void _onRegistrarResult() {
    final command = _vm.registrarCommand;
    if (command.error) {
      _showError(command);
    } else if (command.completed) {
      command.clearResult();
      _codigoController.clear();
    }
  }

  void _onAtivarResult() {
    final command = _vm.ativarCommand;
    if (command.error) {
      _showError(command);
    } else if (command.completed) {
      command.clearResult();
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(strings.translate('contaAtivadaFacaLogin'))));
      context.pop(_vm.emailCadastrado);
    }
  }

  void _showError(Command command) {
    final msgError = _vm.errorMessage(command);
    if (msgError == null) return;

    final strings = AppLocalizations.of(context);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('error'),
        titleButtonPrimary: strings.translate('ok'),
        titleButtonSecondary: strings.translate('ok'),
        isDismissible: false,
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        description: strings.translate(msgError),
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () => context.pop(),
        onPressedSecondary: () => context.pop(),
      ),
    ).showModal(context);

    command.clearResult();
  }

  // ---------- ações ----------

  void _registrar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _vm.registrarCommand.execute((
      email: _emailController.text,
      senha: _senhaController.text,
      confirmacao: _confirmacaoController.text,
    ));
  }

  void _ativar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _vm.ativarCommand.execute((email: _vm.emailCadastrado ?? _emailController.text, codigo: _codigoController.text));
  }

  // ---------- validações (regras no use case; aqui só traduz a chave) ----------

  String? _translate(String? key) => key == null ? null : AppLocalizations.of(context).translate(key);

  String? _validateEmail(String? value) => _translate(_vm.validateEmail(value));

  String? _validateSenha(String? value) => _translate(_vm.validateSenha(value));

  String? _validateConfirmacao(String? value) =>
      _translate(_vm.validateConfirmacao(_senhaController.text, value));

  String? _validateCodigo(String? value) => _translate(_vm.validateCodigo(value));

  // ---------- layout ----------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, child) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ativacao = _vm.etapa == RegistroEtapa.ativacao;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(strings.translate('registro')),
            elevation: 0,
            actions: const [OrientationButton(), ThemeModeButton()],
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RegistroView.icone(
                            ativacao ? RegistroView.iconeCodigo : RegistroView.iconeCabecalho,
                            ativacao ? Icons.verified_user_outlined : Icons.person_add_alt_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            strings.translate(ativacao ? 'ativarConta' : 'criarConta'),
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ...(ativacao ? _ativacaoSection(strings) : _dadosSection(strings)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_vm.running) const Loading(),
      ],
    );
  }

  List<Widget> _dadosSection(AppLocalizations strings) {
    return [
      TextFormField(
        controller: _emailController,
        enabled: !_vm.running,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: strings.translate('email'),
          hintText: strings.translate('informeEmail'),
          prefixIcon: RegistroView.icone(RegistroView.iconeEmail, Icons.email_outlined),
        ),
        validator: _validateEmail,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _senhaController,
        enabled: !_vm.running,
        obscureText: !_senhaVisivel,
        autofillHints: const [AutofillHints.newPassword],
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: strings.translate('senha'),
          hintText: strings.translate('informeSenha'),
          prefixIcon: RegistroView.icone(RegistroView.iconeSenha, Icons.lock_outline),
          suffixIcon: _visibilidadeButton(strings),
        ),
        validator: _validateSenha,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmacaoController,
        enabled: !_vm.running,
        obscureText: !_senhaVisivel,
        autofillHints: const [AutofillHints.newPassword],
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _registrar(),
        decoration: InputDecoration(
          labelText: strings.translate('confirmeSenha'),
          hintText: strings.translate('informeConfirmacaoSenha'),
          prefixIcon: RegistroView.icone(RegistroView.iconeConfirmacao, Icons.lock_outline),
        ),
        validator: _validateConfirmacao,
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: _vm.running ? null : _registrar, child: Text(strings.translate('criarConta'))),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _vm.running ? null : () => context.pop(),
        child: Text(strings.translate('jaTemConta')),
      ),
    ];
  }

  List<Widget> _ativacaoSection(AppLocalizations strings) {
    return [
      Text(
        '${strings.translate('codigoAtivacaoEnviado')}\n${_vm.emailCadastrado ?? ''}',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _codigoController,
        enabled: !_vm.running,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 6,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _ativar(),
        decoration: InputDecoration(
          labelText: strings.translate('codigoAtivacao'),
          hintText: strings.translate('digiteCodigoEnviado'),
          prefixIcon: RegistroView.icone(RegistroView.iconeCodigo, Icons.pin_outlined),
          counterText: '',
        ),
        validator: _validateCodigo,
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: _vm.running ? null : _ativar, child: Text(strings.translate('ativarConta'))),
      const SizedBox(height: 8),
      TextButton(onPressed: _vm.running ? null : _vm.voltarDados, child: Text(strings.translate('corrigirDados'))),
    ];
  }

  Widget _visibilidadeButton(AppLocalizations strings) {
    return IconButton(
      tooltip: strings.translate(_senhaVisivel ? 'ocultarSenha' : 'exibirSenha'),
      icon: _senhaVisivel
          ? RegistroView.icone(RegistroView.iconeOcultar, Icons.visibility_off_outlined)
          : RegistroView.icone(RegistroView.iconeExibir, Icons.visibility_outlined),
      onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
    );
  }
}
