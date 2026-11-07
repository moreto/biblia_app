import 'package:commons/commons.dart';

import '../../../../data/model/configuracao/configuracao_item_model.dart';
import '../../../../data/model/configuracao/configuracao_model.dart';

abstract class ConfiguracaoRepository {
  Future<Result<List<ConfiguracaoModel>>> getConfiguracoes();
  Future<Result<ConfiguracaoModel>> insertConfiguracao(ConfiguracaoModel configuracao);
  Future<Result<ConfiguracaoModel>> updateConfiguracao(ConfiguracaoModel configuracao);
  Future<Result<int>> deleteConfiguracao(int confId);

  Future<Result<List<ConfiguracaoItemModel>>> getItens(int confId);
  Future<Result<ConfiguracaoItemModel>> insertItem(ConfiguracaoItemModel item);
  Future<Result<ConfiguracaoItemModel>> updateItem(ConfiguracaoItemModel item);
  Future<Result<int>> deleteItem(int citeId);
}
