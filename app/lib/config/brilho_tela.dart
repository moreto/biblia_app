import 'package:screen_brightness/screen_brightness.dart';

/// Brilho da tela usado pela leitura (0 a 1).
///
/// Muda só o brilho do app, não o do sistema: ao [restaurar], ou ao fechar o app, o aparelho volta ao brilho
/// que tinha. Em plataformas sem suporte (web, desktop) os métodos lançam; quem chama trata o erro.
abstract interface class BrilhoTela {
  /// Brilho atual do app.
  Future<double> atual();

  /// Define o brilho do app.
  Future<void> definir(double brilho);

  /// Volta ao brilho do sistema.
  Future<void> restaurar();
}

/// [BrilhoTela] do aparelho, pelo pacote `screen_brightness`.
class BrilhoTelaAparelho implements BrilhoTela {
  const BrilhoTelaAparelho();

  @override
  Future<double> atual() => ScreenBrightness.instance.application;

  @override
  Future<void> definir(double brilho) => ScreenBrightness.instance.setApplicationScreenBrightness(brilho);

  @override
  Future<void> restaurar() => ScreenBrightness.instance.resetApplicationScreenBrightness();
}
