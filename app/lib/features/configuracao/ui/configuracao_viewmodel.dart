import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../data/model/configuracao/configuracao_model.dart';
import '../use_case/configuracao_usecase.dart';

class ConfiguracaoViewmodel extends ChangeNotifier {
  ConfiguracaoViewmodel({required this.configuracaoUseCase}) {
    Log.print(super.runtimeType);
    getConfiguracoesCommand.execute();
  }

  final ConfiguracaoUseCase configuracaoUseCase;

  // configuracao

  late final Command0<List<ConfiguracaoModel>> getConfiguracoesCommand = Command0(_getConfiguracoes);
  late final Command1<ConfiguracaoModel, ConfiguracaoModel> saveConfiguracaoCommand = Command1(_saveConfiguracao);
  late final Command1<int, ConfiguracaoModel> deleteConfiguracaoCommand = Command1(_deleteConfiguracao);

  List<ConfiguracaoModel>? _configuracoes;
  List<ConfiguracaoModel>? get configuracoes => _configuracoes;

  // configuracao-item

  late final Command1<List<ConfiguracaoItemModel>, int> getItensCommand = Command1(_getItens);
  late final Command1<ConfiguracaoItemModel, ConfiguracaoItemModel> saveItemCommand = Command1(_saveItem);
  late final Command1<int, ConfiguracaoItemModel> deleteItemCommand = Command1(_deleteItem);

  int? _selectedConfId;
  int? get selectedConfId => _selectedConfId;

  List<ConfiguracaoItemModel>? _itens;
  List<ConfiguracaoItemModel>? get itens => _itens;

  void selectConfiguracao(int? confId) {
    if (_selectedConfId == confId) return;
    _selectedConfId = confId;
    _itens = null;
    notifyListeners();
    if (confId != null) getItensCommand.execute(confId);
  }

  Future<void> refreshItens() async {
    final confId = _selectedConfId;
    if (confId != null) await getItensCommand.execute(confId);
  }

  Future<Result<List<ConfiguracaoModel>>> _getConfiguracoes() async {
    notifyListeners();

    final result = await configuracaoUseCase.getConfiguracoes();
    switch (result) {
      case Ok<List<ConfiguracaoModel>>():
        _configuracoes = result.value;
        final existeSelecionada = result.value.any((item) => item.confId == _selectedConfId);
        if (!existeSelecionada) {
          selectConfiguracao(result.value.isEmpty ? null : result.value.first.confId);
        }
      case Error<List<ConfiguracaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<ConfiguracaoModel>> _saveConfiguracao(ConfiguracaoModel configuracao) async {
    notifyListeners();

    final result = await configuracaoUseCase.saveConfiguracao(configuracao);
    switch (result) {
      case Ok<ConfiguracaoModel>():
        getConfiguracoesCommand.execute();
      case Error<ConfiguracaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<int>> _deleteConfiguracao(ConfiguracaoModel configuracao) async {
    notifyListeners();

    final result = await configuracaoUseCase.deleteConfiguracao(configuracao);
    switch (result) {
      case Ok<int>():
        getConfiguracoesCommand.execute();
      case Error<int>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<List<ConfiguracaoItemModel>>> _getItens(int confId) async {
    notifyListeners();

    final result = await configuracaoUseCase.getItens(confId);
    if (confId != _selectedConfId) {
      // a seleção mudou durante a consulta: descarta a resposta e carrega a selecionada
      // (agendado para depois que este comando liberar o estado running)
      Future(refreshItens);
    } else {
      switch (result) {
        case Ok<List<ConfiguracaoItemModel>>():
          _itens = result.value;
        case Error<List<ConfiguracaoItemModel>>(error: final error):
          Log.print(error.toString(), name: kApp, title: 'Erro');
      }
    }

    notifyListeners();
    return result;
  }

  Future<Result<ConfiguracaoItemModel>> _saveItem(ConfiguracaoItemModel item) async {
    notifyListeners();

    final result = await configuracaoUseCase.saveItem(item);
    switch (result) {
      case Ok<ConfiguracaoItemModel>():
        refreshItens();
      case Error<ConfiguracaoItemModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<int>> _deleteItem(ConfiguracaoItemModel item) async {
    notifyListeners();

    final result = await configuracaoUseCase.deleteItem(item);
    switch (result) {
      case Ok<int>():
        refreshItens();
      case Error<int>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    getConfiguracoesCommand.dispose();
    saveConfiguracaoCommand.dispose();
    deleteConfiguracaoCommand.dispose();
    getItensCommand.dispose();
    saveItemCommand.dispose();
    deleteItemCommand.dispose();
    super.dispose();
  }
}
