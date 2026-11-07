import 'package:commons/commons.dart';

import '../../../data/model/log_model.dart';
import '../repository/log_repository.dart';

class LogUseCase {
  LogUseCase({required this.logRepository}) {
    Log.print(super.runtimeType);
  }

  final LogRepository logRepository;

  Future<Result<List<LogModel>>> getLogs() async {
    final result = await logRepository.getLogs();
    switch (result) {
      case Ok<List<LogModel>>():
        return Result.ok(result.value);
      case Error<List<LogModel>>():
        return Result.error(result.error);
    }
  }
}
