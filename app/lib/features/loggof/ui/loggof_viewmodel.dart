import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../config/usuario_session.dart';

class LoggofViewmodel extends ChangeNotifier {
  void logout() {
    AuthSession.instance.clear();
    UsuarioSession.instance.clear();
    notifyListeners();
  }
}
