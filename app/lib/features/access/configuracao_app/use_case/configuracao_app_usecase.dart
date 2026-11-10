import 'dart:convert';

import 'package:commons/commons.dart';

import '../../../../data/model/configuracao/configuracao_app_model.dart';
import '../repository/configuracao_app_repository.dart';

/// Regras da configuração do app (`GET /v1/configuracao-app`):
///
/// - a configuração é lida uma vez e guardada em [AppSession]; chamadas seguintes usam o que está em memória;
/// - `kCryptKeyB64` é obrigatória e precisa ser uma chave AES-256 (base64 de 32 bytes), senão a configuração é
///   recusada e nada é gravado;
/// - `kAccessTokenId` passa a ser o access token dos headers; sem ele o header vai vazio.
class ConfiguracaoAppUseCase {
  ConfiguracaoAppUseCase({required this.configuracaoAppRepository, AppSession? session})
    : _session = session ?? AppSession.instance;

  final ConfiguracaoAppRepository configuracaoAppRepository;
  final AppSession _session;

  /// Lê a configuração da API se ainda não estiver em memória.
  Future<Result<void>> carregar() async {
    if (_session.isLoaded) return const Result.ok(null);

    final result = await configuracaoAppRepository.listar();
    switch (result) {
      case Ok<List<ConfiguracaoAppModel>>(value: final itens):
        final valores = {for (final item in itens) item.citeChave: item.citeValor.trim()};
        final cryptKeyB64 = valores[kConfCryptKeyB64] ?? kVazio;
        if (!_chaveValida(cryptKeyB64)) {
          return Result.error(HandledException(message: 'configuracaoAppInvalida'));
        }

        _session.setConfiguracao(
          cryptKey: valores[kConfCryptKey],
          cryptKeyB64: cryptKeyB64,
          accessTokenId: valores[kConfAccessTokenId],
        );
        return const Result.ok(null);
      case Error<List<ConfiguracaoAppModel>>():
        return Result.error(result.error);
    }
  }

  /// Chave de criptografia da senha, carregando a configuração se preciso.
  Future<Result<String>> cryptKeyB64() async {
    final result = await carregar();
    switch (result) {
      case Ok<void>():
        return Result.ok(_session.cryptKeyB64!);
      case Error<void>():
        return Result.error(result.error);
    }
  }

  static bool _chaveValida(String base64Key) {
    if (base64Key.isEmpty) return false;
    try {
      return base64Decode(base64Key).length == 32;
    } on FormatException {
      return false;
    }
  }
}
