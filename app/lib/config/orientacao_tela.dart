import 'package:flutter/services.dart';

import 'leitura_preferencia.dart';

/// Trava (ou solta) a orientação da tela. Abstração para os testes.
abstract interface class OrientacaoTela {
  Future<void> aplicar(OrientacaoLeitura orientacao);
}

/// [OrientacaoTela] com `SystemChrome.setPreferredOrientations` (na web e no desktop o sistema ignora).
class OrientacaoTelaSistema implements OrientacaoTela {
  const OrientacaoTelaSistema();

  @override
  Future<void> aplicar(OrientacaoLeitura orientacao) => SystemChrome.setPreferredOrientations(switch (orientacao) {
    // Lista vazia: todas as orientações (segue o aparelho).
    OrientacaoLeitura.automatica => const [],
    OrientacaoLeitura.retrato => const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    OrientacaoLeitura.paisagem => const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
  });
}
