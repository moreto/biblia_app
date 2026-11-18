import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../use_case/home_usecase.dart';

/// Estado da tela de entrada:
/// - [continuar]: último capítulo aberto na leitura ("Continuar de onde parou"), relido com [atualizarContinuar]
///   ao voltar da leitura;
/// - [seletorCommand]: carrega livros e capítulos para "Escolher capítulo" (uma vez; depois usa o [seletor]);
/// - [idDispositivoCommand]: id do aparelho, carregado ao abrir a tela.
class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel({required this.homeUseCase}) {
    _continuar = homeUseCase.continuarLeitura();
    idDispositivoCommand.execute();
  }

  final HomeUseCase homeUseCase;

  late final Command0<String> idDispositivoCommand = Command0(_carregarIdDispositivo);
  late final Command0<SeletorCapitulo> seletorCommand = Command0(_carregarSeletor);

  String? _idDispositivo;
  LeituraDestino? _continuar;
  SeletorCapitulo? _seletor;

  /// Id do aparelho; null enquanto carrega ou se não foi possível ler.
  String? get idDispositivo => _idDispositivo;

  /// Onde "Continuar de onde parou" abre a leitura; null se nenhum capítulo foi aberto ainda.
  LeituraDestino? get continuar => _continuar;

  /// Livros e capítulos de "Escolher capítulo"; null até o primeiro carregamento com sucesso.
  SeletorCapitulo? get seletor => _seletor;

  /// Relê o último capítulo aberto (a leitura grava ao abrir cada capítulo).
  void atualizarContinuar() {
    _continuar = homeUseCase.continuarLeitura();
    notifyListeners();
  }

  Future<Result<String>> _carregarIdDispositivo() async {
    final result = await homeUseCase.idDispositivo();
    if (result case Ok(value: final id)) _idDispositivo = id;
    notifyListeners();
    return result;
  }

  Future<Result<SeletorCapitulo>> _carregarSeletor() async {
    final atual = _seletor;
    if (atual != null) return Result.ok(atual);

    final result = await homeUseCase.seletorCapitulo();
    switch (result) {
      case Ok(value: final seletor):
        _seletor = seletor;
      case Error(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    idDispositivoCommand.dispose();
    seletorCommand.dispose();
    super.dispose();
  }
}
