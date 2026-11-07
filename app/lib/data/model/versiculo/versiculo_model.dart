/// Versículo sorteado com a referência completa, como devolvido por `GET /v1/versiculo/aleatorio`.
class VersiculoModel {
  const VersiculoModel({
    required this.versId,
    required this.versNumero,
    required this.versTexto,
    required this.capiNumero,
    required this.livrId,
    required this.livrNome,
    required this.livrAbrev,
    required this.testNome,
    required this.versaId,
    required this.versaCodigo,
    required this.versaNome,
    required this.versReferencia,
  });

  final int versId;
  final int versNumero;
  final String versTexto;
  final int capiNumero;
  final int livrId;
  final String livrNome;
  final String livrAbrev;
  final String testNome;
  final int versaId;
  final String versaCodigo;
  final String versaNome;

  /// Referência formatada pela API, ex.: "João 3:16 (ARC)".
  final String versReferencia;

  static int _int(Map<String, dynamic> json, String camel, String snake) =>
      ((json[camel] ?? json[snake]) as num).toInt();

  static String _str(Map<String, dynamic> json, String camel, String snake) => (json[camel] ?? json[snake]) as String;

  /// Aceita camelCase (padrão da API) ou snake_case. Sem `versReferencia`, ela é montada com livro, capítulo,
  /// versículo e código da versão.
  factory VersiculoModel.fromJson(Map<String, dynamic> json) {
    final livrNome = _str(json, 'livrNome', 'livr_nome');
    final capiNumero = _int(json, 'capiNumero', 'capi_numero');
    final versNumero = _int(json, 'versNumero', 'vers_numero');
    final versaCodigo = _str(json, 'versaCodigo', 'versa_codigo');
    return VersiculoModel(
      versId: _int(json, 'versId', 'vers_id'),
      versNumero: versNumero,
      versTexto: _str(json, 'versTexto', 'vers_texto'),
      capiNumero: capiNumero,
      livrId: _int(json, 'livrId', 'livr_id'),
      livrNome: livrNome,
      livrAbrev: _str(json, 'livrAbrev', 'livr_abrev'),
      testNome: _str(json, 'testNome', 'test_nome'),
      versaId: _int(json, 'versaId', 'versa_id'),
      versaCodigo: versaCodigo,
      versaNome: _str(json, 'versaNome', 'versa_nome'),
      versReferencia:
          (json['versReferencia'] ?? json['vers_referencia']) as String? ??
          '$livrNome $capiNumero:$versNumero ($versaCodigo)',
    );
  }

  Map<String, dynamic> toJson() => {
    'versId': versId,
    'versNumero': versNumero,
    'versTexto': versTexto,
    'capiNumero': capiNumero,
    'livrId': livrId,
    'livrNome': livrNome,
    'livrAbrev': livrAbrev,
    'testNome': testNome,
    'versaId': versaId,
    'versaCodigo': versaCodigo,
    'versaNome': versaNome,
    'versReferencia': versReferencia,
  };
}
