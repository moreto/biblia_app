import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../data/model/oracao/oracao_model.dart';
import '../repository/oracao_repository.dart';

class OracaoUseCase {
  OracaoUseCase({required this.oracaoRepository}) {
    Log.print(super.runtimeType);
  }

  final OracaoRepository oracaoRepository;

  /// Sorteia uma oração. A API responde 404 `registroNaoEncontrado` quando não há orações cadastradas;
  /// esse caso vira `nenhumaOracaoCadastrada`, para o card não mostrar uma mensagem genérica.
  Future<Result<OracaoModel>> aleatoria() async {
    final result = await oracaoRepository.aleatoria();
    switch (result) {
      case Ok<OracaoModel>():
        return Result.ok(result.value);
      case Error<OracaoModel>(error: final error):
        if (_semOracoes(error)) {
          return Result.error(HandledException(message: 'nenhumaOracaoCadastrada'));
        }
        return Result.error(error);
    }
  }

  static bool _semOracoes(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
