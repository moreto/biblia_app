import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../config/usuario_session.dart';

class LoggofViewmodel extends ChangeNotifier {
  LoggofViewmodel({this.limparDadosLocais});

  /// Apaga do aparelho os dados do usuário que saiu (leitura offline). As marcações ainda não sincronizadas ficam,
  /// para serem enviadas quando ele entrar de novo.
  final Future<void> Function(int usuaId)? limparDadosLocais;

  void logout() {
    final usuaId = AuthSession.instance.userId;
    final limpar = limparDadosLocais;
    if (usuaId != null && limpar != null) {
      unawaited(limpar(usuaId).catchError((Object e) => Log.print(e.toString(), name: kApp, title: 'Erro')));
    }
    AuthSession.instance.clear();
    UsuarioSession.instance.clear();
    notifyListeners();
  }
}
