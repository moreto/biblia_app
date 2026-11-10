import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_denominacao_model.dart';
import '../../../../data/model/comunidade/comunidade_model.dart';
import '../../../../data/model/comunidade/comunidade_tipo_model.dart';
import '../use_case/comunidade_usecase.dart';

/// Estado da tela de comunidades.
///
/// Ao ser criado executa [minhasCommand], que carrega a aba "Minhas comunidades" e as opções do formulário.
/// [salvarCommand] inclui ou altera e [excluirCommand] exclui; os dois recarregam a lista quando dão certo.
/// Novas abas ganham o próprio comando aqui.
class ComunidadeViewmodel extends ChangeNotifier {
  ComunidadeViewmodel({required this.comunidadeUseCase}) {
    Log.print(super.runtimeType);
    minhasCommand.execute();
  }

  final ComunidadeUseCase comunidadeUseCase;

  List<ComunidadeAba> get abas => comunidadeUseCase.abas;

  late final Command0<MinhasComunidades> minhasCommand = Command0(_carregarMinhas);
  late final Command1<ComunidadeModel, ComunidadeModel> salvarCommand = Command1(_salvar);
  late final Command1<void, ComunidadeModel> excluirCommand = Command1(_excluir);

  /// Nulo até o primeiro carregamento concluir. Uma atualização que falha mantém a última lista carregada.
  List<ComunidadeResumo>? _minhas;
  List<ComunidadeResumo>? get minhas => _minhas;

  List<ComunidadeTipoModel> _tipos = const [];
  List<ComunidadeTipoModel> get tipos => _tipos;

  List<ComunidadeDenominacaoModel> _denominacoes = const [];
  List<ComunidadeDenominacaoModel> get denominacoes => _denominacoes;

  /// Gravação ou exclusão em andamento.
  bool get gravando => salvarCommand.running || excluirCommand.running;

  String? descricao(ComunidadeResumo resumo) => ComunidadeUseCase.descricao(resumo);

  /// Chave de tradução do problema do formulário; nula se ele pode ser salvo.
  String? validar(ComunidadeModel comunidade) => comunidadeUseCase.validar(comunidade);

  int get nomeMax => ComunidadeUseCase.kNomeMax;

  Future<Result<MinhasComunidades>> _carregarMinhas() async {
    notifyListeners();

    final result = await comunidadeUseCase.minhasComunidades();
    switch (result) {
      case Ok<MinhasComunidades>(value: final value):
        _minhas = value.comunidades;
        _tipos = value.tipos;
        _denominacoes = value.denominacoes;
      case Error<MinhasComunidades>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<ComunidadeModel>> _salvar(ComunidadeModel comunidade) async {
    notifyListeners();

    final result = await comunidadeUseCase.salvar(comunidade);
    switch (result) {
      case Ok<ComunidadeModel>():
        await _carregarMinhas();
      case Error<ComunidadeModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<void>> _excluir(ComunidadeModel comunidade) async {
    notifyListeners();

    final result = await comunidadeUseCase.excluir(comunidade);
    switch (result) {
      case Ok<void>():
        await _carregarMinhas();
      case Error<void>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    minhasCommand.dispose();
    salvarCommand.dispose();
    excluirCommand.dispose();
    super.dispose();
  }
}
