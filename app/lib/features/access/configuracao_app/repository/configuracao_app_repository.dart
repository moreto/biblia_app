import 'package:commons/commons.dart';

import '../../../../data/model/configuracao/configuracao_app_model.dart';

abstract class ConfiguracaoAppRepository {
  /// Itens ativos da configuração do app (`GET /v1/configuracao-app`), públicos (só `x-access-token`).
  Future<Result<List<ConfiguracaoAppModel>>> listar();
}
