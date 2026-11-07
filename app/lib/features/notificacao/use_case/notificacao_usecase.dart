import 'package:commons/commons.dart';

import '../../../data/model/notificacao_model.dart';
import '../repository/notificacao_repository.dart';

class NotificacaoUseCase {
  NotificacaoUseCase({required this.notificacaoRepository}) {
    Log.print(super.runtimeType);
  }

  final NotificacaoRepository notificacaoRepository;

  Future<Result<List<NotificacaoModel>>> getNotificacoes() async {
    final result = await notificacaoRepository.getNotificacoes();
    switch (result) {
      case Ok<List<NotificacaoModel>>():
        return Result.ok(result.value);
      case Error<List<NotificacaoModel>>():
        return Result.error(result.error);
    }
  }
}
