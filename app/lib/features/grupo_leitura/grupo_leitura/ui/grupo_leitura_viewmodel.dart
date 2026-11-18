import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/leitura/leitura_model.dart';
import '../use_case/grupo_leitura_usecase.dart';

/// Estado da tela de grupos de leitura (aba "Meus grupos").
///
/// Ao ser criado executa [gruposCommand]. [salvarCommand] inclui ou altera e [excluirCommand] exclui; os dois
/// recarregam a lista quando dão certo. Uma atualização que falha mantém a última lista.
class GrupoLeituraViewmodel extends ChangeNotifier {
  GrupoLeituraViewmodel({required this.grupoLeituraUseCase}) {
    Log.print(super.runtimeType);
    gruposCommand.execute();
  }

  final GrupoLeituraUseCase grupoLeituraUseCase;

  List<GrupoLeituraAba> get abas => grupoLeituraUseCase.abas;

  late final Command0<List<LeituraModel>> gruposCommand = Command0(_carregar);
  late final Command1<LeituraModel, LeituraModel> salvarCommand = Command1(_salvar);
  late final Command1<void, LeituraModel> excluirCommand = Command1(_excluir);

  List<LeituraModel>? _grupos;

  /// Nula até o primeiro carregamento concluir.
  List<LeituraModel>? get grupos => _grupos;

  /// Gravação ou exclusão em andamento.
  bool get gravando => salvarCommand.running || excluirCommand.running;

  int get nomeMax => GrupoLeituraUseCase.kNomeMax;
  int get descricaoMax => GrupoLeituraUseCase.kDescricaoMax;

  /// Chave de tradução do problema do formulário; nula se ele pode ser salvo.
  String? validar(LeituraModel grupo) => grupoLeituraUseCase.validar(grupo);

  /// Papel do usuário no grupo (chave de tradução).
  String papel(LeituraModel grupo) => GrupoLeituraUseCase.papel(grupo);

  Future<Result<List<LeituraModel>>> _carregar() async {
    notifyListeners();
    final result = await grupoLeituraUseCase.meusGrupos();
    switch (result) {
      case Ok<List<LeituraModel>>(value: final value):
        _grupos = value;
      case Error<List<LeituraModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<LeituraModel>> _salvar(LeituraModel grupo) async {
    notifyListeners();
    final result = await grupoLeituraUseCase.salvar(grupo);
    switch (result) {
      case Ok<LeituraModel>():
        await _carregar();
      case Error<LeituraModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _excluir(LeituraModel grupo) async {
    notifyListeners();
    final result = await grupoLeituraUseCase.excluir(grupo);
    switch (result) {
      case Ok<void>():
        await _carregar();
      case Error<void>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    gruposCommand.dispose();
    salvarCommand.dispose();
    excluirCommand.dispose();
    super.dispose();
  }
}
