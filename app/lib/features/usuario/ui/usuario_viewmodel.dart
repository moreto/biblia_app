import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/usuario/usuario_configuracao_model.dart';
import '../../../data/model/usuario/usuario_detalhe_model.dart';
import '../use_case/usuario_usecase.dart';

/// Dados do formulário da aba "Dados cadastrais".
typedef UsuarioDadosForm = ({String nome, String usuario});

/// Dados do formulário da aba "Senha".
typedef UsuarioSenhaForm = ({String senhaAtual, String novaSenha, String confirmacao});

/// Estado da tela "Meus dados".
///
/// - [carregarCommand] (executado ao criar) busca o detalhe e a configuração; uma atualização que falha mantém os
///   últimos valores. Recarregar descarta as alterações de configuração ainda não salvas.
/// - [salvarDadosCommand] grava nome e nome de usuário e troca o [detalhe] pelo devolvido.
/// - [alterarSenhaCommand] troca a senha (nada fica guardado no estado).
/// - [configuracaoEditada] guarda as escolhas da aba "Configurações" até [salvarConfiguracaoCommand] gravá-las.
class UsuarioViewmodel extends ChangeNotifier {
  UsuarioViewmodel({required this.usuarioUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final UsuarioUseCase usuarioUseCase;

  late final Command0<UsuarioDados> carregarCommand = Command0(_carregar);
  late final Command1<UsuarioDetalheModel, UsuarioDadosForm> salvarDadosCommand = Command1(_salvarDados);
  late final Command1<void, UsuarioSenhaForm> alterarSenhaCommand = Command1(_alterarSenha);
  late final Command0<UsuarioConfiguracaoModel> salvarConfiguracaoCommand = Command0(_salvarConfiguracao);

  List<UsuarioAba> get abas => UsuarioAba.values;

  UsuarioDetalheModel? _detalhe;

  /// Detalhe do usuário; nulo até o primeiro carregamento concluir.
  UsuarioDetalheModel? get detalhe => _detalhe;

  UsuarioConfiguracaoModel? _configuracao;

  /// Configuração gravada (ou a padrão, sem `uconId`, se ainda não houver).
  UsuarioConfiguracaoModel? get configuracao => _configuracao;

  UsuarioConfiguracaoModel? _configuracaoEditada;

  /// Configuração com as escolhas da tela, ainda não salvas.
  UsuarioConfiguracaoModel? get configuracaoEditada => _configuracaoEditada;

  /// O usuário ainda não gravou configuração (a tela mostra os valores padrão).
  bool get configuracaoPadrao => _configuracao != null && _configuracao?.uconId == null;

  bool get configuracaoAlterada => UsuarioUseCase.configuracaoAlterada(_configuracao, _configuracaoEditada);

  bool get gravando => salvarDadosCommand.running || alterarSenhaCommand.running || salvarConfiguracaoCommand.running;

  bool get ocupado => carregarCommand.running || gravando;

  String get iniciais => _detalhe == null ? '?' : UsuarioUseCase.iniciais(_detalhe!);

  String? data(DateTime? quando) => UsuarioUseCase.data(quando);

  bool dadosAlterados(String nome, String usuario) => UsuarioUseCase.dadosAlterados(_detalhe, nome, usuario);

  String? validateNome(String? nome) => usuarioUseCase.validateNome(nome);
  String? validateUsuario(String? usuario) => usuarioUseCase.validateUsuario(usuario);
  String? validateSenhaAtual(String? senha) => usuarioUseCase.validateSenhaAtual(senha);
  String? validateNovaSenha(String? senhaAtual, String? novaSenha) =>
      usuarioUseCase.validateNovaSenha(senhaAtual, novaSenha);
  String? validateConfirmacao(String? novaSenha, String? confirmacao) =>
      usuarioUseCase.validateConfirmacao(novaSenha, confirmacao);

  bool opcao(UsuarioConfiguracaoOpcao opcao) =>
      _configuracaoEditada != null && UsuarioUseCase.opcao(_configuracaoEditada!, opcao);

  int? quantidade(UsuarioConfiguracaoQuantidade quantidade) =>
      _configuracaoEditada == null ? null : UsuarioUseCase.quantidade(_configuracaoEditada!, quantidade);

  List<int> opcoesQuantidade(UsuarioConfiguracaoQuantidade quantidade) =>
      UsuarioUseCase.opcoesQuantidade(this.quantidade(quantidade) ?? 0);

  void alterarOpcao(UsuarioConfiguracaoOpcao opcao, bool valor) {
    final atual = _configuracaoEditada;
    if (atual == null) return;
    _configuracaoEditada = UsuarioUseCase.comOpcao(atual, opcao, valor);
    notifyListeners();
  }

  void alterarQuantidade(UsuarioConfiguracaoQuantidade quantidade, int valor) {
    final atual = _configuracaoEditada;
    if (atual == null) return;
    _configuracaoEditada = UsuarioUseCase.comQuantidade(atual, quantidade, valor);
    notifyListeners();
  }

  /// Volta as escolhas da aba "Configurações" para a configuração gravada.
  void descartarConfiguracao() {
    _configuracaoEditada = _configuracao;
    notifyListeners();
  }

  Future<Result<UsuarioDados>> _carregar() async {
    notifyListeners();
    final result = await usuarioUseCase.carregar();
    switch (result) {
      case Ok<UsuarioDados>(value: final value):
        _detalhe = value.detalhe;
        _configuracao = value.configuracao;
        _configuracaoEditada = value.configuracao;
      case Error<UsuarioDados>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<UsuarioDetalheModel>> _salvarDados(UsuarioDadosForm form) async {
    final atual = _detalhe;
    if (atual == null) return Result.error(HandledException(message: kDefaultAppError));
    notifyListeners();
    final result = await usuarioUseCase.salvarDados(atual: atual, nome: form.nome, usuario: form.usuario);
    switch (result) {
      case Ok<UsuarioDetalheModel>(value: final value):
        _detalhe = value;
      case Error<UsuarioDetalheModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _alterarSenha(UsuarioSenhaForm form) async {
    notifyListeners();
    final result = await usuarioUseCase.alterarSenha(
      senhaAtual: form.senhaAtual,
      novaSenha: form.novaSenha,
      confirmacao: form.confirmacao,
    );
    if (result case Error(error: final error)) Log.print(error.toString(), name: kApp, title: 'Erro');
    notifyListeners();
    return result;
  }

  Future<Result<UsuarioConfiguracaoModel>> _salvarConfiguracao() async {
    final editada = _configuracaoEditada;
    if (editada == null) return Result.error(HandledException(message: kDefaultAppError));
    notifyListeners();
    final result = await usuarioUseCase.salvarConfiguracao(editada);
    switch (result) {
      case Ok<UsuarioConfiguracaoModel>(value: final value):
        _configuracao = value;
        _configuracaoEditada = value;
      case Error<UsuarioConfiguracaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    salvarDadosCommand.dispose();
    alterarSenhaCommand.dispose();
    salvarConfiguracaoCommand.dispose();
    super.dispose();
  }
}
