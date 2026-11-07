class ConfiguracaoItemModel {
  const ConfiguracaoItemModel({
    this.citeId,
    required this.confId,
    required this.citeCampo,
    this.citeChave,
    this.citeValor,
    this.citeSequencia,
    this.citeAtivo = true,
    this.createdAt,
    this.updatedAt,
  });

  final int? citeId;
  final int confId;
  final String citeCampo;
  final int? citeChave;
  final String? citeValor;
  final int? citeSequencia;
  final bool citeAtivo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isNovo => citeId == null;

  factory ConfiguracaoItemModel.fromJson(Map<String, dynamic> json) {
    final citeId = json['citeId'] ?? json['cite_id'];
    final confId = json['confId'] ?? json['conf_id'];
    final citeChave = json['citeChave'] ?? json['cite_chave'];
    final citeSequencia = json['citeSequencia'] ?? json['cite_sequencia'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'];

    return ConfiguracaoItemModel(
      citeId: (citeId as num).toInt(),
      confId: (confId as num).toInt(),
      citeCampo: (json['citeCampo'] ?? json['cite_campo']) as String,
      citeChave: (citeChave as num?)?.toInt(),
      citeValor: (json['citeValor'] ?? json['cite_valor']) as String?,
      citeSequencia: (citeSequencia as num?)?.toInt(),
      citeAtivo: (json['citeAtivo'] ?? json['cite_ativo']) as bool? ?? true,
      createdAt: createdAt == null ? null : DateTime.parse(createdAt as String),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'citeId': citeId,
    'confId': confId,
    'citeCampo': citeCampo,
    'citeChave': citeChave,
    'citeValor': citeValor,
    'citeSequencia': citeSequencia,
    'citeAtivo': citeAtivo,
  };

  ConfiguracaoItemModel copyWith({
    int? citeId,
    int? confId,
    String? citeCampo,
    int? citeChave,
    String? citeValor,
    int? citeSequencia,
    bool? citeAtivo,
  }) => ConfiguracaoItemModel(
    citeId: citeId ?? this.citeId,
    confId: confId ?? this.confId,
    citeCampo: citeCampo ?? this.citeCampo,
    citeChave: citeChave ?? this.citeChave,
    citeValor: citeValor ?? this.citeValor,
    citeSequencia: citeSequencia ?? this.citeSequencia,
    citeAtivo: citeAtivo ?? this.citeAtivo,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
