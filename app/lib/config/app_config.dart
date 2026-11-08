import 'dart:async';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

/// Preferências de aparência do app (tema e idioma), persistidas em secure storage.
///
/// Chame [load] antes do `runApp` para que a seleção do usuário já seja
/// aplicada no primeiro frame.
class AppConfig extends ChangeNotifier {
  AppConfig({BBSecureStorage? storage}) : _storage = storage ?? BBSecureStorage();

  final BBSecureStorage _storage;

  ThemeMode _mode = ThemeMode.system;
  Locale? _locale;

  ThemeMode get mode => _mode;

  Locale? get locale => _locale;

  /// Lê o tema e o idioma salvos. Valores ausentes ou inválidos mantêm o padrão.
  Future<void> load() async {
    final storedMode = await _storage.readSecureData(kColorScheme);
    _mode = ThemeMode.values.firstWhere((m) => m.name == storedMode, orElse: () => ThemeMode.system);

    final storedLocale = await _storage.readSecureData(kSelectedLanguage);
    _locale = _parseLocale(storedLocale);

    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    unawaited(_storage.writeSecureData(SecureStorageModel(kColorScheme, mode.name)));
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

  /// Converte uma tag como `pt-BR` em [Locale].
  static Locale? _parseLocale(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final parts = tag.split('-');
    return Locale(parts.first, parts.length > 1 ? parts[1] : null);
  }
}
