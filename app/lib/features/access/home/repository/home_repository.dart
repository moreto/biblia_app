import 'package:commons/commons.dart';

import '../../../../data/model/healt_model.dart';

abstract class HomeRepository {
  Future<Result<HealtModel>> healt();
}
