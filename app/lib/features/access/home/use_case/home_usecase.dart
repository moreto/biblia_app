import 'package:commons/commons.dart';

import '../../../../config/device_info.dart';

/// Lê o id do aparelho; lança se a plataforma não tiver essa informação.
typedef LerIdDispositivo = Future<String> Function();

Future<String> _idDoAparelho() async {
  final info = DeviceInfo.instance;
  await info.initialize();
  return info.deviceId;
}

/// Regras da tela de entrada.
class HomeUseCase {
  HomeUseCase({LerIdDispositivo? lerIdDispositivo}) : _lerIdDispositivo = lerIdDispositivo ?? _idDoAparelho;

  final LerIdDispositivo _lerIdDispositivo;

  /// Id do aparelho: Android ID no Android, `identifierForVendor` no iPhone e iPad.
  ///
  /// Na web, no desktop ou se o sistema não devolver o id, falha com `dispositivoNaoIdentificado`.
  Future<Result<String>> idDispositivo() async {
    try {
      final id = await _lerIdDispositivo();
      if (id.isEmpty) return Result.error(HandledException(message: 'dispositivoNaoIdentificado'));
      return Result.ok(id);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Id do dispositivo');
      return Result.error(HandledException(message: 'dispositivoNaoIdentificado'));
    }
  }
}
