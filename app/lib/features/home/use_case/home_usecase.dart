import 'package:commons/commons.dart';

import '../../../data/model/healt_model.dart';
import '../repository/home_repository.dart';

class HomeUseCase {
  HomeUseCase({required this.homeRepository}) {
    Log.print(super.runtimeType);
  }

  final HomeRepository homeRepository;

  Future<Result<HealtModel>> healt() async {
    final result = await homeRepository.healt();
    switch (result) {
      case Ok<HealtModel>():
        return Result.ok(result.value);
      case Error<HealtModel>():
        return Result.error(result.error);
    }
  }
}
