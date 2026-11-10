/// Configuração do app vinda de `GET /v1/configuracao-app`, mantida em memória durante a execução.
///
/// Fica separada de [AuthSession] porque não depende do usuário: é lida antes do login e não é apagada no logoff.
class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  String? _cryptKey;
  String? _cryptKeyB64;
  String? _accessTokenId;

  String? get cryptKey => _cryptKey;

  /// Chave AES-256 (base64, 32 bytes) compartilhada com a API para criptografar a senha.
  String? get cryptKeyB64 => _cryptKeyB64;

  /// Access token devolvido pela API. Antes da primeira leitura o header usa [kAccessTokenId].
  String? get accessTokenId => _accessTokenId;

  /// A configuração já foi lida da API.
  bool get isLoaded => _cryptKeyB64?.isNotEmpty ?? false;

  void setConfiguracao({String? cryptKey, required String cryptKeyB64, String? accessTokenId}) {
    if (cryptKeyB64.isEmpty) {
      throw ArgumentError('configuracaoAppInvalida');
    }

    _cryptKey = cryptKey;
    _cryptKeyB64 = cryptKeyB64;
    _accessTokenId = (accessTokenId?.isEmpty ?? true) ? null : accessTokenId;
  }

  void clear() {
    _cryptKey = null;
    _cryptKeyB64 = null;
    _accessTokenId = null;
  }
}
