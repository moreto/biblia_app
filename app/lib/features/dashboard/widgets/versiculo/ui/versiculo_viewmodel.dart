import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/versiculo/versiculo_model.dart';
import '../../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../../versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import '../use_case/versiculo_usecase.dart';

/// Estado do card de versículo da dashboard: carrega um versículo ao ser criado e sorteia outro a cada
/// `aleatorioCommand.execute()`. Junto com cada versículo carrega a reação de leitura do usuário, que
/// `lidoCommand.execute(comentario)` marca (com o comentário opcional) ou desmarca.
class VersiculoViewmodel extends ChangeNotifier {
  VersiculoViewmodel({required this.versiculoUseCase, required this.versiculoReacaoUseCase}) {
    Log.print(super.runtimeType);
    aleatorioCommand.execute();
  }

  final VersiculoUseCase versiculoUseCase;
  final VersiculoReacaoUseCase versiculoReacaoUseCase;

  late final Command0<VersiculoModel> aleatorioCommand = Command0(_aleatorio);

  /// Argumento: comentário digitado ao marcar como lido; ignorado ao desmarcar.
  late final Command1<VersiculoReacaoModel, String?> lidoCommand = Command1(_alternarLido);

  /// Último versículo carregado; continua visível enquanto outro é sorteado ou se o novo sorteio falhar.
  VersiculoModel? _versiculo;
  VersiculoModel? get versiculo => _versiculo;

  /// Reação do usuário ao [versiculo]; nula se ele ainda não reagiu ou se a consulta falhou.
  VersiculoReacaoModel? _reacao;
  VersiculoReacaoModel? get reacao => _reacao;

  bool get lido => _reacao?.vreaLido ?? false;

  Future<Result<VersiculoModel>> _aleatorio() async {
    notifyListeners();

    final result = await versiculoUseCase.aleatorio();
    switch (result) {
      case Ok<VersiculoModel>(value: final versiculo):
        // A reação acompanha o versículo; se a consulta falhar o card mostra o versículo como não lido.
        final reacao = await versiculoReacaoUseCase.minhaReacao(versiculo.versId);
        if (reacao case Error(error: final error)) {
          Log.print(error.toString(), name: kApp, title: 'Erro');
        }
        _versiculo = versiculo;
        _reacao = reacao is Ok<VersiculoReacaoModel?> ? reacao.value : null;
      case Error<VersiculoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<VersiculoReacaoModel>> _alternarLido(String? comentario) async {
    final versiculo = _versiculo;
    if (versiculo == null) {
      return Result.error(HandledException(message: 'formatoVersiculoInvalido'));
    }
    notifyListeners();

    final result = await versiculoReacaoUseCase.alternarLido(versiculo.versId, _reacao, comentario: comentario);
    switch (result) {
      case Ok<VersiculoReacaoModel>(value: final reacao):
        // Ignora a resposta se outro versículo foi sorteado enquanto a reação era gravada.
        if (_versiculo?.versId == reacao.versId) {
          _reacao = reacao;
        }
      case Error<VersiculoReacaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    aleatorioCommand.dispose();
    lidoCommand.dispose();
    super.dispose();
  }
}
