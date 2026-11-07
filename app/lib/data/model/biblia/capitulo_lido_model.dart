import 'json_reader.dart';

/// Progresso de leitura do usuário em um capítulo (`GET /v1/versiculo-reacao/lidos/:versaId`).
class CapituloLidoModel {
  const CapituloLidoModel({
    required this.livrId,
    required this.livrNome,
    required this.livrAbrev,
    required this.capiNumero,
    required this.versTotal,
    required this.versLidos,
    this.lidoEm,
  });

  final int livrId;
  final String livrNome;
  final String livrAbrev;
  final int capiNumero;
  final int versTotal;
  final int versLidos;

  /// Última gravação de um versículo lido do capítulo.
  final DateTime? lidoEm;

  /// Todos os versículos do capítulo estão marcados como lidos.
  bool get completo => versTotal > 0 && versLidos >= versTotal;

  /// Chave do capítulo no mapa de lidos do viewmodel.
  String get chave => chaveDe(livrId, capiNumero);

  static String chaveDe(int livrId, int capiNumero) => '$livrId:$capiNumero';

  factory CapituloLidoModel.fromJson(Map<String, dynamic> json) => CapituloLidoModel(
    livrId: JsonReader.inteiro(json, 'livrId', 'livr_id'),
    livrNome: JsonReader.texto(json, 'livrNome', 'livr_nome'),
    livrAbrev: JsonReader.textoOpcional(json, 'livrAbrev', 'livr_abrev') ?? '',
    capiNumero: JsonReader.inteiro(json, 'capiNumero', 'capi_numero'),
    versTotal: JsonReader.inteiroOpcional(json, 'versTotal', 'vers_total') ?? 0,
    versLidos: JsonReader.inteiroOpcional(json, 'versLidos', 'vers_lidos') ?? 0,
    lidoEm: JsonReader.data(json, 'lidoEm', 'lido_em'),
  );
}
