/// Reação de um usuário a um versículo (`biblia.versiculo_reacao`), como devolvida por `/v1/versiculo-reacao`.
///
/// [vreaId] é nulo enquanto a reação não foi gravada (corpo do POST).
class VersiculoReacaoModel {
  const VersiculoReacaoModel({
    this.vreaId,
    required this.versId,
    this.usuaId,
    this.vreaComentario,
    required this.vreaLido,
  });

  final int? vreaId;
  final int versId;

  /// Dono da reação. Na gravação a API usa o usuário do token e ignora o valor enviado.
  final int? usuaId;
  final String? vreaComentario;

  /// Reação de leitura: o usuário marcou o versículo como lido.
  final bool vreaLido;

  static int? _int(Map<String, dynamic> json, String camel, String snake) =>
      ((json[camel] ?? json[snake]) as num?)?.toInt();

  /// Aceita camelCase (padrão da API) ou snake_case.
  factory VersiculoReacaoModel.fromJson(Map<String, dynamic> json) => VersiculoReacaoModel(
    vreaId: _int(json, 'vreaId', 'vrea_id'),
    versId: _int(json, 'versId', 'vers_id')!,
    usuaId: _int(json, 'usuaId', 'usua_id'),
    vreaComentario: (json['vreaComentario'] ?? json['vrea_comentario']) as String?,
    vreaLido: (json['vreaLido'] ?? json['vrea_lido']) as bool,
  );

  /// Corpo do POST/PUT. Campos nulos (como [vreaId] numa inclusão) são removidos pelo DioProvider.
  Map<String, dynamic> toJson() => {
    'vreaId': vreaId,
    'versId': versId,
    'vreaComentario': vreaComentario,
    'vreaLido': vreaLido,
  };

  VersiculoReacaoModel copyWith({bool? vreaLido}) => VersiculoReacaoModel(
    vreaId: vreaId,
    versId: versId,
    usuaId: usuaId,
    vreaComentario: vreaComentario,
    vreaLido: vreaLido ?? this.vreaLido,
  );
}
