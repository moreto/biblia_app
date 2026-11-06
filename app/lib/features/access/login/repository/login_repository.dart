import 'package:commons/commons.dart';

import '../../../../data/model/healt_model.dart';

abstract class LoginRepository {
  Future<Result<HealtModel>> healt();
}
