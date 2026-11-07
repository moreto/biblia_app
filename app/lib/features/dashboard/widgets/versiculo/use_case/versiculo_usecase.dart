import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/versiculo/versiculo_model.dart';
import '../repository/versiculo_repository.dart';

class VersiculoUseCase {
  VersiculoUseCase({required this.versiculoRepository}) {
    Log.print(super.runtimeType);
  }

  final VersiculoRepository versiculoRepository;

  /// Sorteia um versículo. A API responde 404 `registroNaoEncontrado` quando não há versículos cadastrados;
  /// esse caso vira `nenhumVersiculoCadastrado`, para o card não mostrar uma mensagem genérica.
  Future<Result<VersiculoModel>> aleatorio() async {
    final result = await versiculoRepository.aleatorio();
    switch (result) {
      case Ok<VersiculoModel>():
        return Result.ok(result.value);
      case Error<VersiculoModel>(error: final error):
        if (_semVersiculos(error)) {
          return Result.error(HandledException(message: 'nenhumVersiculoCadastrado'));
        }
        return Result.error(error);
    }
  }

  static bool _semVersiculos(Exception error) =>
      (error is HttpServiceException && error.message == kRegistroNaoEncontrado) ||
      (error is HandledException && error.message == kRegistroNaoEncontrado);

  static const kRegistroNaoEncontrado = 'registroNaoEncontrado';
}
