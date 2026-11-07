import 'package:commons/commons.dart';

import '../../../data/model/notificacao_model.dart';

abstract class NotificacaoRepository {
  Future<Result<List<NotificacaoModel>>> getNotificacoes();
}
