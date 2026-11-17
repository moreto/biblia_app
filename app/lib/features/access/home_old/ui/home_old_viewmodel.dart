import 'package:app/config/command.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/healt_model.dart';
import '../use_case/home_old_usecase.dart';

class HomeOldViewmodel extends ChangeNotifier {
  HomeOldViewmodel({required this.homeOldUseCase}) {
    healtCommand.execute();
  }

  final HomeOldUseCase homeOldUseCase;

  late final Command0<HealtModel> healtCommand = Command0(_healt);
  late HealtModel _healtModel;
  HealtModel get healtModel => _healtModel;

  Future<Result<HealtModel>> _healt() async {
    notifyListeners();

    final result = await homeOldUseCase.healt();
    switch (result) {
      case Ok<HealtModel>():
        _healtModel = result.value;
      case Error<HealtModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }
}
