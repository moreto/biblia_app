import 'package:commons/commons.dart';

import '../../../../data/model/healt_model.dart';
import '../repository/login_repository.dart';

class LoginUseCase {
  LoginUseCase({required this.loginRepository});

  final LoginRepository loginRepository;

  Future<Result<HealtModel>> healt() async {
    final result = await loginRepository.healt();
    switch (result) {
      case Ok<HealtModel>():
        return Result.ok(result.value);
      case Error<HealtModel>():
        return Result.error(result.error);
    }
  }
}
