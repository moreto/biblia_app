import 'package:commons/commons.dart';

import '../../../../data/model/healt_model.dart';
import '../repository/home_old_repository.dart';

class HomeOldUseCase {
  HomeOldUseCase({required this.homeOldRepository});

  final HomeOldRepository homeOldRepository;

  Future<Result<HealtModel>> healt() async {
    final result = await homeOldRepository.healt();
    switch (result) {
      case Ok<HealtModel>():
        return Result.ok(result.value);
      case Error<HealtModel>():
        return Result.error(result.error);
    }
  }
}
