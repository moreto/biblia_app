class NotificacaoModel {
  const NotificacaoModel({
    required this.notiId,
    required this.notiData,
    required this.notiTipo,
    required this.notiTexto,
    required this.usuaId,
    required this.logId,
    required this.logTipo,
    required this.logInfo,
    required this.logTexto,
  });

  final int notiId;
  final DateTime notiData;
  final String notiTipo;
  final String? notiTexto;
  final int? usuaId;
  final int? logId;
  final String? logTipo;
  final String? logInfo;
  final String? logTexto;

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    final notiId = json['notiId'] ?? json['noti_id'];
    final notiData = json['notiData'] ?? json['noti_data'];
    final usuaId = json['usuaId'] ?? json['usua_id'];
    final logId = json['logId'] ?? json['log_id'];

    return NotificacaoModel(
      notiId: (notiId as num).toInt(),
      notiData: DateTime.parse(notiData as String),
      notiTipo: (json['notiTipo'] ?? json['noti_tipo']) as String,
      notiTexto: json['notiTexto'] as String? ?? json['noti_texto'] as String?,
      usuaId: (usuaId as num?)?.toInt(),
      logId: (logId as num?)?.toInt(),
      logTipo: json['logTipo'] as String? ?? json['log_tipo'] as String?,
      logInfo: json['logInfo'] as String? ?? json['log_info'] as String?,
      logTexto: json['logTexto'] as String? ?? json['log_texto'] as String?,
    );
  }
}
