import 'package:app/config/app_config.dart';
import 'package:app/config/leitura_preferencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig tema', () {
    test('grava e lê cada tema, compatível com o ThemeMode já gravado', () {
      for (final tema in TemaApp.values) {
        expect(AppConfig.parseTema(AppConfig.gravarTema(tema)), tema);
      }
      expect(AppConfig.gravarTema(TemaApp.escuro), 'dark');
      expect(AppConfig.parseTema('light'), TemaApp.claro);
      expect(AppConfig.parseTema(null), TemaApp.sistema);
      expect(AppConfig.parseTema('xpto'), TemaApp.sistema);
    });

    test('creme usa o modo claro do MaterialApp', () {
      expect(TemaApp.creme.mode, ThemeMode.light);
    });
  });
}
