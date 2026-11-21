import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ditado pela tela pronta do sistema (no Android, a janela "Fale agora" do Google): o usuário fala e o texto
/// volta pronto.
///
/// O microfone do teclado não pode ser aberto por um app; este é o atalho mais próximo. Abstração para os testes.
abstract interface class DitadoSistema {
  /// O aparelho tem a tela de ditado.
  Future<bool> disponivel();

  /// Abre a tela de ditado em [idioma] (ex.: `pt-BR`) com a [dica]; devolve o texto falado, ou nulo se o usuário
  /// cancelou ou nada foi reconhecido.
  Future<String?> ditar({required String idioma, String? dica});
}

/// [DitadoSistema] pelo canal com a `MainActivity` do Android; nas outras plataformas fica indisponível (lá vale
/// o microfone do teclado).
class DitadoSistemaAparelho implements DitadoSistema {
  const DitadoSistemaAparelho();

  static const _canal = MethodChannel('br.com.moreto.biblia.app/ditado');

  bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> disponivel() async {
    if (!_android) return false;
    try {
      return await _canal.invokeMethod<bool>('disponivel') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<String?> ditar({required String idioma, String? dica}) async {
    try {
      return await _canal.invokeMethod<String>('ditar', {'idioma': idioma, 'dica': dica});
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
