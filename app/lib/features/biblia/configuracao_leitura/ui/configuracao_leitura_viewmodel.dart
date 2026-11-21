import 'package:app/config/leitura_preferencia.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';

import '../use_case/configuracao_leitura_usecase.dart';

/// Estado da Configurações de leitura: a orientação da tela escolhida.
class ConfiguracaoLeituraViewmodel extends ChangeNotifier {
  ConfiguracaoLeituraViewmodel({required this.configuracaoLeituraUseCase}) {
    Log.print(super.runtimeType);
  }

  final ConfiguracaoLeituraUseCase configuracaoLeituraUseCase;

  OrientacaoLeitura get orientacao => configuracaoLeituraUseCase.orientacao;

  void setOrientacao(OrientacaoLeitura orientacao) {
    if (orientacao == this.orientacao) return;
    configuracaoLeituraUseCase.salvarOrientacao(orientacao);
    notifyListeners();
  }

  /// Volta a orientação ao padrão (automática).
  void restaurarPadrao() => setOrientacao(OrientacaoLeitura.automatica);
}
