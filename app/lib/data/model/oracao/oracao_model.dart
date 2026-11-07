/// Oração de `biblia.oracao`, como devolvida por `GET /v1/oracao/aleatoria`.
class OracaoModel {
  const OracaoModel({required this.oracId, required this.oracNome, required this.oracTexto});

  final int oracId;
  final String oracNome;
  final String oracTexto;

  factory OracaoModel.fromJson(Map<String, dynamic> json) => OracaoModel(
    oracId: ((json['oracId'] ?? json['orac_id']) as num).toInt(),
    oracNome: (json['oracNome'] ?? json['orac_nome']) as String,
    oracTexto: (json['oracTexto'] ?? json['orac_texto']) as String,
  );

  Map<String, dynamic> toJson() => {'oracId': oracId, 'oracNome': oracNome, 'oracTexto': oracTexto};
}
