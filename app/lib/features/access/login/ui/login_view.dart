import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/command.dart';
import '../../../../routing/routes.dart';
import 'login_viewmodel.dart';

import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.viewModel});

  final LoginViewmodel viewModel;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'mmoreto@gmail.com');
  final _senhaController = TextEditingController(text: '123');
  final _codigoController = TextEditingController();
  bool _senhaVisivel = false;

  LoginViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _addListeners(_vm);
  }

  @override
  void didUpdateWidget(covariant LoginView oldWidget) {
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
    _codigoController.dispose();
    super.dispose();
  }

  void _addListeners(LoginViewmodel vm) {
    vm.loginCommand.addListener(_onLoginResult);
    vm.otpVerifyCommand.addListener(_onOtpVerifyResult);
    vm.otpSendCommand.addListener(_onOtpSendResult);
  }

  void _removeListeners(LoginViewmodel vm) {
    vm.loginCommand.removeListener(_onLoginResult);
    vm.otpVerifyCommand.removeListener(_onOtpVerifyResult);
    vm.otpSendCommand.removeListener(_onOtpSendResult);
  }

  void _onLoginResult() => _handleLoginCommand(_vm.loginCommand);

  void _onOtpVerifyResult() => _handleLoginCommand(_vm.otpVerifyCommand);

  void _handleLoginCommand(Command command) {
    if (command.error) {
      _showError(command);
    } else if (command.completed) {
      command.clearResult();
      context.go(Routes.dashboard);
    }
  }

  void _onOtpSendResult() {
    final command = _vm.otpSendCommand;
    if (command.error) {
      _showError(command);
    } else if (command.completed) {
      command.clearResult();
      _codigoController.clear();
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

  void _submitSenha() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _vm.loginCommand.execute((email: _emailController.text, senha: _senhaController.text));
  }

  void _enviarCodigo() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _vm.otpSendCommand.execute(_emailController.text);
  }

  void _submitCodigo() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _vm.otpVerifyCommand.execute((email: _emailController.text, otp: _codigoController.text));
  }

  void _setMode(LoginMode mode) {
    _senhaController.clear();
    _codigoController.clear();
    _vm.setMode(mode);
  }

  // ---------- validações (regras no use case; aqui só traduz a chave) ----------

  String? _translate(String? key) => key == null ? null : AppLocalizations.of(context).translate(key);

  String? _validateEmail(String? value) => _translate(_vm.validateEmail(value));

  String? _validateSenha(String? value) => _translate(_vm.validateSenha(value));

  String? _validateCodigo(String? value) => _translate(_vm.validateCodigo(value));

  // ---------- layout ----------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, child) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(strings.translate('login')),
            elevation: 0,
            actions: const [OrientationButton(), ThemeModeButton()],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          Text(
                            strings.translate(_vm.mode == LoginMode.senha ? 'efetueLogin' : 'loginPorOTP'),
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _emailField(strings),
                          const SizedBox(height: 16),
                          ...switch (_vm.mode) {
                            LoginMode.senha => _senhaSection(strings),
                            LoginMode.codigo => _codigoSection(strings),
                          },
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

  Widget _emailField(AppLocalizations strings) {
    return TextFormField(
      controller: _emailController,
      enabled: !_vm.running,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      textInputAction: TextInputAction.next,
      onChanged: (_) => _vm.onEmailChanged(),
      decoration: InputDecoration(
        labelText: strings.translate('email'),
        hintText: strings.translate('informeEmail'),
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: _validateEmail,
    );
  }

  List<Widget> _senhaSection(AppLocalizations strings) {
    return [
      TextFormField(
        controller: _senhaController,
        enabled: !_vm.running,
        obscureText: !_senhaVisivel,
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submitSenha(),
        decoration: InputDecoration(
          labelText: strings.translate('senha'),
          hintText: strings.translate('informeSenha'),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: strings.translate(_senhaVisivel ? 'ocultarSenha' : 'exibirSenha'),
            icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
          ),
        ),
        validator: _validateSenha,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _vm.running ? null : () => _setMode(LoginMode.codigo),
          child: Text(strings.translate('esqueceuSenhaCodigo')),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _vm.running ? null : _submitSenha, child: Text(strings.translate('login'))),
    ];
  }

  List<Widget> _codigoSection(AppLocalizations strings) {
    if (!_vm.codigoEnviado) {
      return [
        Text(strings.translate('enviaremosCodigoAcesso'), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: _vm.running ? null : _enviarCodigo, child: Text(strings.translate('enviarCodigo'))),
        const SizedBox(height: 8),
        _voltarSenhaButton(strings),
      ];
    }

    return [
      Text(strings.translate('codigoEnviadoSeguro'), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      TextFormField(
        controller: _codigoController,
        enabled: !_vm.running,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 6,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submitCodigo(),
        decoration: InputDecoration(
          labelText: strings.translate('codigoAcesso'),
          hintText: strings.translate('digiteCodigoEnviado'),
          prefixIcon: const Icon(Icons.pin_outlined),
          counterText: '',
        ),
        validator: _validateCodigo,
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: _vm.running ? null : _submitCodigo, child: Text(strings.translate('login'))),
      const SizedBox(height: 8),
      TextButton(onPressed: _vm.running ? null : _enviarCodigo, child: Text(strings.translate('reenviarCodigo'))),
      _voltarSenhaButton(strings),
    ];
  }

  Widget _voltarSenhaButton(AppLocalizations strings) {
    return TextButton(
      onPressed: _vm.running ? null : () => _setMode(LoginMode.senha),
      child: Text(strings.translate('voltarSenha')),
    );
  }
}
