import 'package:commons/commons.dart';

import '../data/model/traducao_model.dart';

abstract class TraducaoRepository {
  Future<Result<List<TraducaoModel>>> get();
}
