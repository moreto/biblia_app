import 'package:flutter_tts/flutter_tts.dart';

/// Voz de fala instalada no aparelho.
///
/// [qualidade] vem do motor de fala: no Android `very high`, `high`, `normal`, `low`, `very low`; no iOS `premium`,
/// `enhanced`, `default`. [online] indica voz que precisa de internet (no Android, em geral as neurais do Google).
class VozNarracao {
  const VozNarracao({
    required this.nome,
    required this.locale,
    this.qualidade,
    this.online = false,
    this.identificador,
    this.instalada = true,
  });

  final String nome;

  /// Idioma da voz (ex.: `pt-BR`, `pt_BR`).
  final String locale;
  final String? qualidade;
  final bool online;

  /// Identificador da voz no iOS.
  final String? identificador;

  /// Falso quando o motor lista a voz mas ela não está baixada (no Android, a característica `notInstalled`): ao
  /// escolhê-la, o motor fala com a voz padrão, então ela fica fora da lista.
  final bool instalada;

  /// Voz a partir do mapa devolvido pelo `flutter_tts` (`getVoices`); nula se faltar nome ou idioma.
  static VozNarracao? fromMap(Map<dynamic, dynamic> mapa) {
    final nome = mapa['name']?.toString();
    final locale = mapa['locale']?.toString();
    if (nome == null || nome.isEmpty || locale == null || locale.isEmpty) return null;
    return VozNarracao(
      nome: nome,
      locale: locale,
      qualidade: mapa['quality']?.toString(),
      online: mapa['network_required']?.toString() == '1',
      identificador: mapa['identifier']?.toString(),
      instalada: !(mapa['features']?.toString().contains('notInstalled') ?? false),
    );
  }

  Map<String, String> toMap() => {'name': nome, 'locale': locale, 'identifier': ?identificador};
}

/// Leitura em voz alta (texto para fala) da narração da Bíblia.
///
/// Abstração sobre o plugin `flutter_tts` para poder ser substituída nos testes.
abstract interface class NarracaoVoz {
  /// Vozes instaladas no aparelho (de todos os idiomas).
  Future<List<VozNarracao>> vozes();

  /// Fala [texto] na [voz] (ou na padrão do [idioma], ex.: `pt-BR`) e na [velocidade] (0,5 = normal); o futuro
  /// termina quando a fala acaba ou é interrompida por [parar].
  Future<void> falar(String texto, {required String idioma, VozNarracao? voz, double velocidade = 0.5});

  /// Interrompe a fala atual.
  Future<void> parar();
}

/// [NarracaoVoz] com o motor de fala do aparelho (`flutter_tts`).
class NarracaoVozAparelho implements NarracaoVoz {
  NarracaoVozAparelho({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _preparado = false;
  String? _idioma;
  double? _velocidade;

  @override
  Future<List<VozNarracao>> vozes() async {
    final lista = await _tts.getVoices;
    if (lista is! List) return const [];
    return [
      for (final item in lista)
        if (item is Map)
          if (VozNarracao.fromMap(item) case final voz? when voz.instalada) voz,
    ];
  }

  @override
  Future<void> falar(String texto, {required String idioma, VozNarracao? voz, double velocidade = 0.5}) async {
    if (!_preparado) {
      await _tts.awaitSpeakCompletion(true);
      _preparado = true;
    }
    if (_idioma != idioma) {
      await _tts.setLanguage(idioma);
      _idioma = idioma;
    }
    // A voz vai a cada fala: o motor pode voltar à padrão (ao reconectar ou ao trocar o idioma), e guardar a última
    // aqui fazia a troca de voz não valer.
    if (voz != null) await _tts.setVoice(voz.toMap());
    if (_velocidade != velocidade) {
      await _tts.setSpeechRate(velocidade);
      _velocidade = velocidade;
    }
    await _tts.speak(texto);
  }

  @override
  Future<void> parar() async => _tts.stop();
}
