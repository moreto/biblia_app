import 'package:flutter/material.dart';

class AppConfig extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  Locale? _locale;

  ThemeMode get mode => _mode;

  Locale? get locale => _locale;

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;

    notifyListeners();
  }

  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
