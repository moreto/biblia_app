import 'package:commons/commons.dart';

import '../../../../../../data/model/funcionalidade/funcionalidade_model.dart';
import '../repository/funcionalidade_repository.dart';

class FuncionalidadeUseCase {
  FuncionalidadeUseCase({required this.funcionalidadeRepository}) {
    Log.print(super.runtimeType);
  }

  final FuncionalidadeRepository funcionalidadeRepository;

  /// Funcionalidades na ordem da API (agrupadas por contexto). Lista vazia vira
  /// `nenhumaFuncionalidadeCadastrada`, para o card mostrar uma mensagem em vez de ficar em branco.
  Future<Result<List<FuncionalidadeModel>>> listar() async {
    final result = await funcionalidadeRepository.listar();
    switch (result) {
      case Ok<List<FuncionalidadeModel>>():
        if (result.value.isEmpty) {
          return Result.error(HandledException(message: 'nenhumaFuncionalidadeCadastrada'));
        }
        return Result.ok(result.value);
      case Error<List<FuncionalidadeModel>>():
        return Result.error(result.error);
    }
  }
}
