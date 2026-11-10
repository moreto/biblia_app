import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/renomado_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_renomado_model.dart';
import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../use_case/versiculo_renomado_usecase.dart';

/// Versículos do renomado [renoId].
///
/// Ao ser criado executa [carregarCommand]: versões e, na versão escolhida pelo usuário, os versículos.
/// [versaoCommand] troca (e salva) a versão e recarrega os versículos; [destino] diz onde a leitura abre.
class VersiculoRenomadoViewmodel extends ChangeNotifier {
  VersiculoRenomadoViewmodel({required this.versiculoRenomadoUseCase, required this.renoId, this.renomado}) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  final VersiculoRenomadoUseCase versiculoRenomadoUseCase;
  final int renoId;

  /// Renomado vindo da lista (nome e texto do cabeçalho); nulo quando a tela é aberta só pelo id.
  final RenomadoModel? renomado;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, VersaoModel> versaoCommand = Command1(_trocarVersao);

  List<VersaoModel> _versoes = const [];
  List<VersaoModel> get versoes => _versoes;

  VersaoModel? _versao;
  VersaoModel? get versao => _versao;

  /// Nulo até o primeiro carregamento concluir. Uma troca de versão que falha mantém a lista anterior.
  List<VersiculoRenomadoModel>? _versiculos;
  List<VersiculoRenomadoModel>? get versiculos => _versiculos;

  LeituraDestino destino(VersiculoRenomadoModel versiculo) => versiculoRenomadoUseCase.destino(versiculo);

  Future<Result<void>> _carregar() async {
    notifyListeners();

    final versoes = await versiculoRenomadoUseCase.versoes();
    switch (versoes) {
      case Ok<List<VersaoModel>>(value: final value):
        _versoes = value;
      case Error<List<VersaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        notifyListeners();
        return Result.error(error);
    }

    final versao = _versao ?? versiculoRenomadoUseCase.versaoInicial(_versoes);
    if (versao == null) {
      notifyListeners();
      return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));
    }

    final result = await _carregarVersiculos(versao);
    notifyListeners();
    return result;
  }

  Future<Result<void>> _trocarVersao(VersaoModel versao) async {
    if (versao.versaId == _versao?.versaId) return const Result.ok(null);
    notifyListeners();

    final result = await _carregarVersiculos(versao);
    if (result is Ok) versiculoRenomadoUseCase.salvarVersao(versao);

    notifyListeners();
    return result;
  }

  Future<Result<void>> _carregarVersiculos(VersaoModel versao) async {
    final result = await versiculoRenomadoUseCase.versiculos(renoId, versao.versaId);
    switch (result) {
      case Ok<List<VersiculoRenomadoModel>>(value: final value):
        _versao = versao;
        _versiculos = value;
        return const Result.ok(null);
      case Error<List<VersiculoRenomadoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    versaoCommand.dispose();
    super.dispose();
  }
}
