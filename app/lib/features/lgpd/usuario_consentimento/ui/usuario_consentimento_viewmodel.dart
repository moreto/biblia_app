import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/usuario/usuario_consentimento_model.dart';
import '../use_case/usuario_consentimento_usecase.dart';

/// Estado da tela "Privacidade e consentimentos" (LGPD).
///
/// - [carregarCommand] (executado ao criar) busca os termos e o histórico; uma atualização que falha mantém a última
///   lista.
/// - [aceitarCommand], [aceitarTodosCommand] e [revogarCommand] gravam e trocam a lista pela devolvida. Se uma
///   gravação falhar, a lista é recarregada (o "aceitar todos" pode ter aceitado parte dos termos).
class UsuarioConsentimentoViewmodel extends ChangeNotifier {
  UsuarioConsentimentoViewmodel({required this.usuarioConsentimentoUseCase}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final UsuarioConsentimentoUseCase usuarioConsentimentoUseCase;

  late final Command0<UsuarioConsentimentoListaModel> carregarCommand = Command0(_carregar);
  late final Command1<UsuarioConsentimentoListaModel, UsuarioConsentimentoTermoModel> aceitarCommand = Command1(
    (termo) => _aplicar(usuarioConsentimentoUseCase.aceitar(termo)),
  );
  late final Command0<UsuarioConsentimentoListaModel> aceitarTodosCommand = Command0(
    () => _aplicar(usuarioConsentimentoUseCase.aceitarPendentes(termos)),
  );
  late final Command1<UsuarioConsentimentoListaModel, UsuarioConsentimentoTermoModel> revogarCommand = Command1(
    (termo) => _aplicar(usuarioConsentimentoUseCase.revogar(termo)),
  );

  UsuarioConsentimentoListaModel? _lista;

  /// Termos e histórico; nula até o primeiro carregamento concluir.
  UsuarioConsentimentoListaModel? get lista => _lista;

  List<UsuarioConsentimentoTermoModel> get termos => _lista?.termos ?? const [];

  List<UsuarioConsentimentoModel> get historico => _lista?.historico ?? const [];

  List<UsuarioConsentimentoTermoModel> get pendentes => UsuarioConsentimentoUseCase.pendentes(termos);

  bool get todosAceitos => UsuarioConsentimentoUseCase.todosAceitos(termos);

  bool get gravando => aceitarCommand.running || aceitarTodosCommand.running || revogarCommand.running;

  bool get ocupado => carregarCommand.running || gravando;

  UsuarioConsentimentoModel? aceite(UsuarioConsentimentoTermoModel termo) =>
      UsuarioConsentimentoUseCase.aceite(termo, historico);

  String titulo(String finalidade) => UsuarioConsentimentoUseCase.titulo(finalidade);

  String? descricao(String finalidade) => UsuarioConsentimentoUseCase.descricao(finalidade);

  String icone(String finalidade) => UsuarioConsentimentoUseCase.icone(finalidade);

  String? avisoRevogacao(String finalidade) => UsuarioConsentimentoUseCase.avisoRevogacao(finalidade);

  String? data(DateTime? quando) => UsuarioConsentimentoUseCase.data(quando);

  Future<Result<UsuarioConsentimentoListaModel>> _carregar() async {
    notifyListeners();
    final result = await usuarioConsentimentoUseCase.carregar();
    switch (result) {
      case Ok<UsuarioConsentimentoListaModel>(value: final value):
        _lista = value;
      case Error<UsuarioConsentimentoListaModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  /// Executa a gravação e troca a lista pela devolvida; com erro, recarrega a lista.
  Future<Result<UsuarioConsentimentoListaModel>> _aplicar(
    Future<Result<UsuarioConsentimentoListaModel>> gravacao,
  ) async {
    notifyListeners();
    final result = await gravacao;
    switch (result) {
      case Ok<UsuarioConsentimentoListaModel>(value: final value):
        _lista = value;
      case Error<UsuarioConsentimentoListaModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        if (await usuarioConsentimentoUseCase.carregar() case Ok(value: final atual)) _lista = atual;
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    aceitarCommand.dispose();
    aceitarTodosCommand.dispose();
    revogarCommand.dispose();
    super.dispose();
  }
}
