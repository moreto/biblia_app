import 'package:commons/commons.dart';

import '../../../data/model/menu/menu_model.dart';

abstract class DashboardRepository {
  Future<Result<MenuModel>> menu();

  /// Quantidade de mensagens não lidas e não arquivadas do usuário logado (`GET /v1/mensagem-usuario/nao-lidas`).
  Future<Result<int>> mensagensNaoLidas();
}
