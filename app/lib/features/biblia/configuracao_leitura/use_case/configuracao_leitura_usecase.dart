import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/orientacao_tela.dart';
import 'package:commons/commons.dart';

/// Regras da Configurações de leitura:
/// - a orientação da tela na leitura é automática (segue o aparelho), retrato ou paisagem; a escolha é guardada
///   ([leituraPreferencia]) e aplicada na hora ([orientacaoTela]); a leitura a aplica ao abrir e solta ao sair.
class ConfiguracaoLeituraUseCase {
  ConfiguracaoLeituraUseCase({required this.leituraPreferencia, this.orientacaoTela}) {
    Log.print(super.runtimeType);
  }

  final LeituraPreferencia leituraPreferencia;

  /// Trava a orientação da tela; nulo só guarda a escolha.
  final OrientacaoTela? orientacaoTela;

  OrientacaoLeitura get orientacao => leituraPreferencia.orientacao;

  /// Guarda e aplica a [orientacao].
  Future<void> salvarOrientacao(OrientacaoLeitura orientacao) async {
    leituraPreferencia.setOrientacao(orientacao);
    await orientacaoTela?.aplicar(orientacao);
  }
}
