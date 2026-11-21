import 'dart:async';

import 'package:commons/commons.dart';
import 'package:components/components.dart' show HighlightColor;
import 'package:flutter/material.dart';

import 'leitura_preferencia.dart';
import 'ultimo_capitulo_preferencia.dart';
import 'versao_preferencia.dart';

/// Preferências do usuário (tema, idioma, versão da Bíblia, último capítulo aberto e fonte da leitura), persistidas em
/// secure storage.
///
/// Chame [load] antes do `runApp` para que a seleção do usuário já seja
/// aplicada no primeiro frame.
class AppConfig extends ChangeNotifier implements VersaoPreferencia, UltimoCapituloPreferencia, LeituraPreferencia {
  AppConfig({BBSecureStorage? storage}) : _storage = storage ?? BBSecureStorage();

  final BBSecureStorage _storage;

  TemaApp _tema = TemaApp.sistema;
  TemaApp _temaLeitura = TemaApp.sistema;
  Locale? _locale;
  int? _versaoId;
  UltimoCapitulo? _ultimoCapitulo;
  double _escalaFonte = 1;
  bool _mostrarSetas = true;
  MarcarAoPassar _marcarAoPassar = MarcarAoPassar.perguntar;
  String? _vozNarracao;
  double? _velocidadeNarracao;
  bool _narracaoContinua = false;
  OrientacaoLeitura _orientacao = OrientacaoLeitura.automatica;
  double? _brilhoLeitura;
  HighlightColor _corMarcaTexto = HighlightColor.amarelo;

  /// Tema do app inteiro.
  TemaApp get tema => _tema;

  @override
  TemaApp get temaLeitura => _temaLeitura;

  @override
  void setTemaLeitura(TemaApp tema) {
    if (_temaLeitura == tema) return;
    _temaLeitura = tema;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingTheme, tema.name)));
  }

  /// Modo do `MaterialApp`; o tema claro é o creme quando [tema] é [TemaApp.creme].
  ThemeMode get mode => _tema.mode;

  Locale? get locale => _locale;

  @override
  int? get versaoId => _versaoId;

  @override
  UltimoCapitulo? get ultimoCapitulo => _ultimoCapitulo;

  @override
  double get escalaFonte => _escalaFonte;

  @override
  bool get mostrarSetas => _mostrarSetas;

  @override
  MarcarAoPassar get marcarAoPassar => _marcarAoPassar;

  @override
  String? get vozNarracao => _vozNarracao;

  @override
  double? get velocidadeNarracao => _velocidadeNarracao;

  @override
  bool get narracaoContinua => _narracaoContinua;

  /// Lê o tema, o idioma, a versão da Bíblia e o último capítulo salvos. Valores ausentes ou inválidos mantêm o padrão.
  Future<void> load() async {
    final storedMode = await _storage.readSecureData(kColorScheme);
    _tema = parseTema(storedMode);

    final storedTemaLeitura = await _storage.readSecureData(kReadingTheme);
    _temaLeitura = TemaApp.values.where((t) => t.name == storedTemaLeitura).firstOrNull ?? TemaApp.sistema;

    final storedLocale = await _storage.readSecureData(kSelectedLanguage);
    _locale = _parseLocale(storedLocale);

    final storedVersao = await _storage.readSecureData(kSelectedBibleVersion);
    _versaoId = int.tryParse(storedVersao ?? '');

    _ultimoCapitulo = parseUltimoCapitulo(await _storage.readSecureData(kLastReadChapter));

    final storedEscala = double.tryParse(await _storage.readSecureData(kReadingFontScale) ?? '');
    if (storedEscala != null && storedEscala > 0) _escalaFonte = storedEscala;

    _mostrarSetas = await _storage.readSecureData(kReadingShowArrows) != 'false';

    _vozNarracao = await _storage.readSecureData(kReadingVoice);
    _velocidadeNarracao = double.tryParse(await _storage.readSecureData(kReadingSpeechRate) ?? '');
    _narracaoContinua = await _storage.readSecureData(kReadingAutoTurn) == 'true';

    _brilhoLeitura = double.tryParse(await _storage.readSecureData(kReadingBrightness) ?? '');
    final storedCor = await _storage.readSecureData(kReadingHighlightColor);
    _corMarcaTexto = HighlightColor.values.where((c) => c.name == storedCor).firstOrNull ?? _corMarcaTexto;

    final storedOrientacao = await _storage.readSecureData(kReadingOrientation);
    _orientacao = OrientacaoLeitura.values.where((o) => o.name == storedOrientacao).firstOrNull ?? _orientacao;

    final storedMarcar = await _storage.readSecureData(kReadingMarkOnTurn);
    _marcarAoPassar = MarcarAoPassar.values.where((m) => m.name == storedMarcar).firstOrNull ?? _marcarAoPassar;

    notifyListeners();
  }

  /// Troca para sistema, claro ou escuro (sai do creme).
  void setMode(ThemeMode mode) => setTema(TemaApp.values.firstWhere((t) => t != TemaApp.creme && t.mode == mode));

  void setTema(TemaApp tema) {
    if (_tema == tema) return;
    _tema = tema;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kColorScheme, gravarTema(tema))));
  }

  /// Valor gravado do tema: o nome do `ThemeMode` (`system`, `light`, `dark`, compatível com o que já estava
  /// gravado) ou `creme`.
  static String gravarTema(TemaApp tema) => tema == TemaApp.creme ? 'creme' : tema.mode.name;

  /// Tema a partir do valor gravado por [gravarTema]; ausente ou inválido segue o sistema.
  static TemaApp parseTema(String? valor) {
    if (valor == 'creme') return TemaApp.creme;
    return TemaApp.values.firstWhere((t) => t != TemaApp.creme && t.mode.name == valor, orElse: () => TemaApp.sistema);
  }

  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    if (locale == null) {
      unawaited(_storage.deleteSecureDataByKey(kSelectedLanguage));
    } else {
      unawaited(_storage.writeSecureData(SecureStorageModel(kSelectedLanguage, locale.toLanguageTag())));
    }
  }

  @override
  void setVersaoId(int versaId) {
    if (_versaoId == versaId) return;
    _versaoId = versaId;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kSelectedBibleVersion, '$versaId')));
  }

  @override
  void setUltimoCapitulo(UltimoCapitulo capitulo) {
    if (_ultimoCapitulo == capitulo) return;
    _ultimoCapitulo = capitulo;
    notifyListeners();

    final valor = '${capitulo.versaId}:${capitulo.livrId}:${capitulo.capiNumero}';
    unawaited(_storage.writeSecureData(SecureStorageModel(kLastReadChapter, valor)));
  }

  @override
  void setVozNarracao(String? nome) {
    if (_vozNarracao == nome) return;
    _vozNarracao = nome;
    notifyListeners();

    if (nome == null) {
      unawaited(_storage.deleteSecureDataByKey(kReadingVoice));
    } else {
      unawaited(_storage.writeSecureData(SecureStorageModel(kReadingVoice, nome)));
    }
  }

  @override
  void setNarracaoContinua(bool continua) {
    if (_narracaoContinua == continua) return;
    _narracaoContinua = continua;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingAutoTurn, '$continua')));
  }

  @override
  HighlightColor get corMarcaTexto => _corMarcaTexto;

  @override
  void setCorMarcaTexto(HighlightColor cor) {
    if (_corMarcaTexto == cor) return;
    _corMarcaTexto = cor;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingHighlightColor, cor.name)));
  }

  @override
  double? get brilhoLeitura => _brilhoLeitura;

  @override
  void setBrilhoLeitura(double? brilho) {
    if (_brilhoLeitura == brilho) return;
    _brilhoLeitura = brilho;
    notifyListeners();

    if (brilho == null) {
      unawaited(_storage.deleteSecureDataByKey(kReadingBrightness));
    } else {
      unawaited(_storage.writeSecureData(SecureStorageModel(kReadingBrightness, '$brilho')));
    }
  }

  @override
  OrientacaoLeitura get orientacao => _orientacao;

  @override
  void setOrientacao(OrientacaoLeitura orientacao) {
    if (_orientacao == orientacao) return;
    _orientacao = orientacao;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingOrientation, orientacao.name)));
  }

  @override
  void setVelocidadeNarracao(double velocidade) {
    if (_velocidadeNarracao == velocidade) return;
    _velocidadeNarracao = velocidade;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingSpeechRate, '$velocidade')));
  }

  @override
  void setMarcarAoPassar(MarcarAoPassar valor) {
    if (_marcarAoPassar == valor) return;
    _marcarAoPassar = valor;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingMarkOnTurn, valor.name)));
  }

  @override
  void setMostrarSetas(bool mostrar) {
    if (_mostrarSetas == mostrar) return;
    _mostrarSetas = mostrar;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingShowArrows, '$mostrar')));
  }

  @override
  void setEscalaFonte(double escala) {
    if (_escalaFonte == escala) return;
    _escalaFonte = escala;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kReadingFontScale, '$escala')));
  }

  /// Converte `versaId:livrId:capiNumero` no capítulo; nulo se ausente ou inválido.
  static UltimoCapitulo? parseUltimoCapitulo(String? valor) {
    final partes = (valor ?? '').split(':').map(int.tryParse).toList();
    if (partes.length != 3 || partes.any((p) => p == null || p < 1)) return null;
    return (versaId: partes[0]!, livrId: partes[1]!, capiNumero: partes[2]!);
  }

  /// Converte uma tag como `pt-BR` em [Locale].
  static Locale? _parseLocale(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final parts = tag.split('-');
    return Locale(parts.first, parts.length > 1 ? parts[1] : null);
  }
}
