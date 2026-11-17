import 'package:commons/commons.dart';

import '../../../../data/model/healt_model.dart';

abstract class HomeOldRepository {
  Future<Result<HealtModel>> healt();
}
