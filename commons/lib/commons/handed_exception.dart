class HandledException implements Exception {
  String message;
  int? code;

  @override
  String toString() {
    return 'HandledException{message: $message, code: $code}';
  }

  HandledException({required this.message, this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HandledException && runtimeType == other.runtimeType && message == other.message && code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code ?? 0);
}
