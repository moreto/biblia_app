import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado da conexão do aparelho.
///
/// Ter conexão (Wi-Fi, dados móveis) não garante que a API responda; serve para não esperar o timeout quando o
/// aparelho está claramente sem rede e para sincronizar quando a conexão volta.
abstract interface class Conectividade {
  /// Último estado conhecido; começa como conectado até a primeira verificação.
  bool get online;

  /// Emite a cada mudança de estado (true = conectado).
  Stream<bool> get mudancas;

  /// Consulta o estado atual e atualiza [online].
  Future<bool> verificar();
}

/// [Conectividade] pelo `connectivity_plus`.
class ConectividadePlus implements Conectividade {
  ConectividadePlus({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  bool _online = true;
  Stream<bool>? _mudancas;

  @override
  bool get online => _online;

  static bool _conectado(List<ConnectivityResult> resultados) => resultados.any((r) => r != ConnectivityResult.none);

  @override
  Stream<bool> get mudancas => _mudancas ??= _connectivity.onConnectivityChanged
      .map(_conectado)
      .map((online) => _online = online)
      .distinct()
      .asBroadcastStream();

  @override
  Future<bool> verificar() async {
    try {
      _online = _conectado(await _connectivity.checkConnectivity());
    } catch (_) {
      // Sem o plugin (ex.: testes), assume conectado e deixa a API decidir.
      _online = true;
    }
    return _online;
  }
}
