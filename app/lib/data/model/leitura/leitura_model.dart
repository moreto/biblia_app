import '../biblia/json_reader.dart';

/// Grupo de leitura (`biblia.leitura`; `/v1/leitura`).
///
/// [leitDono] vem só de `GET /v1/leitura` (grupos do usuário do token): `true` quando o grupo é dele. Só o dono
/// altera o grupo, a agenda e as atividades.
class LeituraModel {
  const LeituraModel({
    this.leitId,
    required this.leitNome,
    this.usuaId,
    this.leitDescricao,
    this.leitDono = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Nulo enquanto o grupo não foi gravado.
  final int? leitId;
  final String leitNome;

  /// Dono do grupo (o usuário do token na gravação; o do corpo é ignorado pela API).
  final int? usuaId;
  final String? leitDescricao;
  final bool leitDono;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Aceita camelCase ou snake_case; datas em hora local.
  factory LeituraModel.fromJson(Map<String, dynamic> json) => LeituraModel(
    leitId: JsonReader.inteiroOpcional(json, 'leitId', 'leit_id'),
    leitNome: JsonReader.texto(json, 'leitNome', 'leit_nome'),
    usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
    leitDescricao: JsonReader.textoOpcional(json, 'leitDescricao', 'leit_descricao'),
    leitDono: switch (json['leitDono'] ?? json['leit_dono']) {
      null => false,
      final bool valor => valor,
      _ => throw const FormatException('campoInvalido', 'leitDono'),
    },
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
    updatedAt: JsonReader.data(json, 'updatedAt', 'updated_at')?.toLocal(),
  );

  /// Corpo do POST/PUT ([leitId] só no PUT; campos nulos são removidos pelo DioProvider).
  Map<String, dynamic> toJson() => {'leitId': leitId, 'leitNome': leitNome, 'leitDescricao': leitDescricao};

  /// Cópia com o [leitDono] informado (a gravação não devolve esse campo).
  LeituraModel comDono(bool dono) => LeituraModel(
    leitId: leitId,
    leitNome: leitNome,
    usuaId: usuaId,
    leitDescricao: leitDescricao,
    leitDono: dono,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
