import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/registro_model.dart';
import '../use_case/registro_usecase.dart';

/// Etapas do cadastro: dados de acesso e, depois do cadastro, o código de ativação enviado ao e-mail.
enum RegistroEtapa { dados, ativacao }

/// Chama o [RegistroUseCase] e notifica a view. As regras ficam no use case.
class RegistroViewmodel extends ChangeNotifier {
  RegistroViewmodel({required this.registroUseCase}) {
    Log.print(super.runtimeType);
    for (final command in _commands) {
      command.addListener(notifyListeners);
    }
  }

  final RegistroUseCase registroUseCase;

  late final Command1<RegistroModel, ({String email, String senha, String confirmacao})> registrarCommand = Command1(
    _registrar,
  );
  late final Command1<void, ({String email, String codigo, String nome, String usuario})> ativarCommand = Command1(
    _ativar,
  );

  List<Command> get _commands => [registrarCommand, ativarCommand];

  RegistroEtapa _etapa = RegistroEtapa.dados;
  RegistroEtapa get etapa => _etapa;

  /// E-mail cadastrado; é para ele que o código de ativação foi enviado.
  String? _emailCadastrado;
  String? get emailCadastrado => _emailCadastrado;

  bool get running => _commands.any((command) => command.running);

  // ---------- validações (chaves de tradução) ----------

  String? validateEmail(String? email) => registroUseCase.validateEmail(email);
  String? validateSenha(String? senha) => registroUseCase.validateSenha(senha);
  String? validateConfirmacao(String? senha, String? confirmacao) =>
      registroUseCase.validateConfirmacao(senha, confirmacao);
  String? validateCodigo(String? codigo) => registroUseCase.validateCodigo(codigo);
  String? validateNome(String? nome) => registroUseCase.validateNome(nome);
  String? validateUsuario(String? usuario) => registroUseCase.validateUsuario(usuario);

  /// Chave de tradução do erro do último resultado de [command], ou null se não houve erro.
  String? errorMessage(Command command) => switch (command.result) {
    Error(error: final error) => registroUseCase.errorMessage(error),
    _ => null,
  };

  // ---------- estado da tela ----------

  /// Volta aos dados de acesso (por exemplo, para corrigir o e-mail).
  void voltarDados() {
    if (_etapa == RegistroEtapa.dados) return;
    _etapa = RegistroEtapa.dados;
    notifyListeners();
  }

  // ---------- chamadas ----------

  Future<Result<RegistroModel>> _registrar(({String email, String senha, String confirmacao}) args) async {
    final result = await registroUseCase.registrar(email: args.email, senha: args.senha, confirmacao: args.confirmacao);
    switch (result) {
      case Ok<RegistroModel>(value: final registro):
        _emailCadastrado = registro.usuaEmail;
        _etapa = RegistroEtapa.ativacao;
      case Error<RegistroModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return result;
  }

  Future<Result<void>> _ativar(({String email, String codigo, String nome, String usuario}) args) async {
    final result = await registroUseCase.ativar(
      email: args.email,
      codigo: args.codigo,
      nome: args.nome,
      usuario: args.usuario,
    );
    if (result case Error(error: final error)) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return result;
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
