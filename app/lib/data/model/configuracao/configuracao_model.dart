class ConfiguracaoModel {
  const ConfiguracaoModel({
    this.confId,
    required this.confNome,
    this.confTipo,
    this.confAtivo = true,
    this.createdAt,
    this.updatedAt,
  });

  final int? confId;
  final String confNome;
  final int? confTipo;
  final bool confAtivo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isNovo => confId == null;

  factory ConfiguracaoModel.fromJson(Map<String, dynamic> json) {
    final confId = json['confId'] ?? json['conf_id'];
    final confTipo = json['confTipo'] ?? json['conf_tipo'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'];

    return ConfiguracaoModel(
      confId: (confId as num).toInt(),
      confNome: (json['confNome'] ?? json['conf_nome']) as String,
      confTipo: (confTipo as num?)?.toInt(),
      confAtivo: (json['confAtivo'] ?? json['conf_ativo']) as bool? ?? true,
      createdAt: createdAt == null ? null : DateTime.parse(createdAt as String),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'confId': confId,
    'confNome': confNome,
    'confTipo': confTipo,
    'confAtivo': confAtivo,
  };

  ConfiguracaoModel copyWith({int? confId, String? confNome, int? confTipo, bool? confAtivo}) => ConfiguracaoModel(
    confId: confId ?? this.confId,
    confNome: confNome ?? this.confNome,
    confTipo: confTipo ?? this.confTipo,
    confAtivo: confAtivo ?? this.confAtivo,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
