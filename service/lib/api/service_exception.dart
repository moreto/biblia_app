class HttpServiceException implements Exception {
  HttpServiceException({this.exception, this.message, this.code, this.debugMessage, this.api});

  Exception? exception;
  String? message;
  Map<String, dynamic>? debugMessage;
  num? code;

  /// API que gerou o erro, no formato `VERBO url` (ex.: `GET http://.../v1/versiculo-reacao/lidos/3`).
  String? api;

  @override
  String toString() => 'HttpServiceException(code: $code, message: $message, api: $api)';
}
