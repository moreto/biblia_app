class HttpServiceException implements Exception {
  HttpServiceException({this.exception, this.message, this.code, this.debugMessage});

  Exception? exception;
  String? message;
  Map<String, dynamic>? debugMessage;
  num? code;
}
