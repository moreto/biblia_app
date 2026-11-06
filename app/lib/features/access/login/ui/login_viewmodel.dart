import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/login_model.dart';
import '../use_case/login_usecase.dart';

enum LoginMode { senha, codigo }

/// Chama o [LoginUseCase] e notifica a view. As regras ficam no use case.
class LoginViewmodel extends ChangeNotifier {
  LoginViewmodel({required this.loginUseCase}) {
    for (final command in _commands) {
      command.addListener(notifyListeners);
    }
  }

  final LoginUseCase loginUseCase;

  late final Command1<LoginModel, ({String email, String senha})> loginCommand = Command1(_login);
  late final Command1<void, String> otpSendCommand = Command1(_otpSend);
  late final Command1<LoginModel, ({String email, String otp})> otpVerifyCommand = Command1(_otpVerify);

  List<Command> get _commands => [loginCommand, otpSendCommand, otpVerifyCommand];

  LoginMode _mode = LoginMode.senha;
  LoginMode get mode => _mode;

  /// True depois que o código OTP foi pedido para o e-mail atual.
  bool _codigoEnviado = false;
  bool get codigoEnviado => _codigoEnviado;

  bool get running => _commands.any((command) => command.running);

  // ---------- validações (chaves de tradução) ----------

  String? validateEmail(String? email) => loginUseCase.validateEmail(email);
  String? validateSenha(String? senha) => loginUseCase.validateSenha(senha);
  String? validateCodigo(String? codigo) => loginUseCase.validateCodigo(codigo);

  /// Chave de tradução do erro do último resultado de [command], ou null se não houve erro.
  String? errorMessage(Command command) => switch (command.result) {
    Error(error: final error) => loginUseCase.errorMessage(error),
    _ => null,
  };

  // ---------- estado da tela ----------

  void setMode(LoginMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _codigoEnviado = false;
    notifyListeners();
  }

  /// Ao trocar o e-mail, o código enviado para o anterior deixa de valer na tela.
  void onEmailChanged() {
    if (!_codigoEnviado) return;
    _codigoEnviado = false;
    notifyListeners();
  }

  // ---------- chamadas ----------

  Future<Result<LoginModel>> _login(({String email, String senha}) args) async {
    final result = await loginUseCase.login(email: args.email, senha: args.senha);
    _logError(result);
    return result;
  }

  Future<Result<void>> _otpSend(String email) async {
    final result = await loginUseCase.otpSend(email: email);
    if (result is Ok) _codigoEnviado = true;
    _logError(result);
    return result;
  }

  Future<Result<LoginModel>> _otpVerify(({String email, String otp}) args) async {
    final result = await loginUseCase.otpVerify(email: args.email, otp: args.otp);
    _logError(result);
    return result;
  }

  void _logError(Result result) {
    if (result case Error(error: final error)) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  @override
  void dispose() {
    for (final command in _commands) {
      command.removeListener(notifyListeners);
      command.dispose();
    }
    super.dispose();
  }
}
