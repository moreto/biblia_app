/// Leitura tolerante dos campos devolvidos pela API: aceita camelCase (padrão da API) ou snake_case e números
/// como `num` ou texto.
abstract final class JsonReader {
  static Object? _valor(Map<String, dynamic> json, String camel, String snake) => json[camel] ?? json[snake];

  /// Inteiro obrigatório; lança [FormatException] se ausente ou inválido.
  static int inteiro(Map<String, dynamic> json, String camel, String snake) =>
      inteiroOpcional(json, camel, snake) ?? (throw FormatException('campoInvalido', camel));

  static int? inteiroOpcional(Map<String, dynamic> json, String camel, String snake) {
    final valor = _valor(json, camel, snake);
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  /// Texto obrigatório; lança [FormatException] se ausente.
  static String texto(Map<String, dynamic> json, String camel, String snake) =>
      textoOpcional(json, camel, snake) ?? (throw FormatException('campoInvalido', camel));

  static String? textoOpcional(Map<String, dynamic> json, String camel, String snake) =>
      _valor(json, camel, snake) as String?;

  static DateTime? data(Map<String, dynamic> json, String camel, String snake) {
    final valor = _valor(json, camel, snake);
    return valor is String ? DateTime.tryParse(valor) : null;
  }
}
