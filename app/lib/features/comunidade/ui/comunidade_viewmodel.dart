import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../use_case/comunidade_usecase.dart';

/// Estado da tela de comunidades.
///
/// Ao ser criado executa [minhasCommand], que carrega a aba "Minhas comunidades". Novas abas ganham o próprio
/// comando aqui.
class ComunidadeViewmodel extends ChangeNotifier {
  ComunidadeViewmodel({required this.comunidadeUseCase}) {
    Log.print(super.runtimeType);
    minhasCommand.execute();
  }

  final ComunidadeUseCase comunidadeUseCase;

  List<ComunidadeAba> get abas => comunidadeUseCase.abas;

  late final Command0<List<ComunidadeResumo>> minhasCommand = Command0(_carregarMinhas);

  /// Nulo até o primeiro carregamento concluir. Uma atualização que falha mantém a última lista carregada.
  List<ComunidadeResumo>? _minhas;
  List<ComunidadeResumo>? get minhas => _minhas;

  String? descricao(ComunidadeResumo resumo) => ComunidadeUseCase.descricao(resumo);

  Future<Result<List<ComunidadeResumo>>> _carregarMinhas() async {
    notifyListeners();

    final result = await comunidadeUseCase.minhasComunidades();
    switch (result) {
      case Ok<List<ComunidadeResumo>>(value: final value):
        _minhas = value;
      case Error<List<ComunidadeResumo>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    minhasCommand.dispose();
    super.dispose();
  }
}
