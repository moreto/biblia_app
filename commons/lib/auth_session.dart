class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? _token;
  int? _userId;
  int? _emprId;

  String? get token => _token;
  int? get userId => _userId;
  int? get emprId => _emprId;

  void setLoggedUser({required String token, required int userId, int? emprId}) {
    if (token.isEmpty || userId <= 0) {
      throw ArgumentError('tokenInvalido');
    }

    _token = token;
    _userId = userId;
    _emprId = emprId;
  }

  void setEmpresa({required int emprId}) {
    if (emprId <= 0) {
      throw ArgumentError('tokenInvalido');
    }

    _emprId = emprId;
  }

  void clear() {
    _token = null;
    _userId = null;
    _emprId = null;
  }
}
