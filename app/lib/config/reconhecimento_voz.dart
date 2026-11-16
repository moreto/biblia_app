import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Reconhecimento de fala (ditado) para preencher campos de texto pela voz.
///
/// Abstração sobre o plugin `speech_to_text` para poder ser substituída nos testes.
abstract interface class ReconhecimentoVoz {
  /// Prepara o reconhecimento e pede as permissões (microfone e, no iOS, reconhecimento de fala).
  ///
  /// Retorna `false` se o aparelho não tem reconhecimento de fala ou se o usuário negou a permissão.
  Future<bool> iniciar();

  /// Começa a ouvir no idioma [localeId] (ex.: `pt_BR`).
  ///
  /// [onResultado] recebe o texto reconhecido até o momento; `definitivo` é `true` no resultado definitivo.
  /// [onFim] é chamado uma vez quando a escuta termina (resultado final, silêncio, erro ou [parar]/[cancelar]);
  /// `erro` vem preenchido quando terminou por erro (ex.: `error_no_match`, `error_speech_timeout`).
  Future<void> ouvir({
    required String localeId,
    required void Function(String texto, bool definitivo) onResultado,
    required void Function(String? erro) onFim,
  });

  /// Para de ouvir e entrega o resultado final do que já foi falado.
  Future<void> parar();

  /// Para de ouvir descartando o resultado.
  Future<void> cancelar();
}

/// [ReconhecimentoVoz] com o reconhecimento nativo do aparelho (`speech_to_text`).
class SpeechToTextReconhecimentoVoz implements ReconhecimentoVoz {
  SpeechToTextReconhecimentoVoz({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  /// Escuta atual; `null` quando não está ouvindo ou quando [onFim] já foi chamado.
  void Function(String? erro)? _onFim;

  /// Tempo máximo ouvindo e de silêncio antes de encerrar.
  static const ouvirPor = Duration(seconds: 10);
  static const pausaMaxima = Duration(seconds: 3);

  @override
  Future<bool> iniciar() async {
    try {
      return await _speech.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus) _terminar(null);
        },
        onError: (erro) => _terminar(erro.errorMsg),
      );
    } catch (_) {
      return false;
    }
  }

  void _terminar(String? erro) {
    final onFim = _onFim;
    _onFim = null;
    onFim?.call(erro);
  }

  @override
  Future<void> ouvir({
    required String localeId,
    required void Function(String texto, bool definitivo) onResultado,
    required void Function(String? erro) onFim,
  }) async {
    _onFim = onFim;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          onResultado(r.recognizedWords, r.finalResult);
          if (r.finalResult) _terminar(null);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: ouvirPor,
          pauseFor: pausaMaxima,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.search,
        ),
      );
    } catch (e) {
      _terminar('$e');
    }
  }

  @override
  Future<void> parar() => _speech.stop();

  @override
  Future<void> cancelar() async {
    await _speech.cancel();
    _terminar(null);
  }
}
