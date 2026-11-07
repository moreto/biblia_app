import 'package:commons/commons.dart';

import '../../../data/model/log_model.dart';

abstract class LogRepository {
  Future<Result<List<LogModel>>> getLogs();
}
