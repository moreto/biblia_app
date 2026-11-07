class LogModel {
  const LogModel({
    required this.logId,
    required this.logTipo,
    required this.logData,
    required this.logInfo,
    required this.usuaId,
    required this.logTexto,
  });

  final int logId;
  final String? logTipo;
  final DateTime logData;
  final String? logInfo;
  final int? usuaId;
  final String? logTexto;

  factory LogModel.fromJson(Map<String, dynamic> json) {
    final logId = json['logId'] ?? json['log_id'];
    final logData = json['logData'] ?? json['log_data'];
    final usuaId = json['usuaId'] ?? json['usua_id'];

    return LogModel(
      logId: (logId as num).toInt(),
      logTipo: json['logTipo'] as String? ?? json['log_tipo'] as String?,
      logData: DateTime.parse(logData as String),
      logInfo: json['logInfo'] as String? ?? json['log_info'] as String?,
      usuaId: (usuaId as num?)?.toInt(),
      logTexto: json['logTexto'] as String? ?? json['log_texto'] as String?,
    );
  }
}
