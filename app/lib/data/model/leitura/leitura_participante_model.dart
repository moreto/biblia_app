import '../biblia/json_reader.dart';

/// Participante de um grupo de leitura (`biblia.leitura_participante`; `/v1/leitura-participante`).
///
/// [udetNome] e [udetUsuario] vêm de `public.usuario_detalhe` no GET (nulos se a API não os devolver); não vão no
/// corpo.
class LeituraParticipanteModel {
  const LeituraParticipanteModel({
    this.lparId,
    required this.leitId,
    required this.usuaId,
    this.udetNome,
    this.udetUsuario,
    this.createdAt,
  });

  /// Nulo enquanto o participante não foi gravado.
  final int? lparId;
  final int leitId;

  /// Usuário participante (não é o do token).
  final int usuaId;
  final String? udetNome;
  final String? udetUsuario;
  final DateTime? createdAt;

  factory LeituraParticipanteModel.fromJson(Map<String, dynamic> json) => LeituraParticipanteModel(
    lparId: JsonReader.inteiroOpcional(json, 'lparId', 'lpar_id'),
    leitId: JsonReader.inteiro(json, 'leitId', 'leit_id'),
    usuaId: JsonReader.inteiro(json, 'usuaId', 'usua_id'),
    udetNome: JsonReader.textoOpcional(json, 'udetNome', 'udet_nome'),
    udetUsuario: JsonReader.textoOpcional(json, 'udetUsuario', 'udet_usuario'),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
  );

  /// Corpo do POST/PUT (campos nulos são removidos pelo DioProvider).
  Map<String, dynamic> toJson() => {'lparId': lparId, 'leitId': leitId, 'usuaId': usuaId};

  /// Cópia com o nome e o nome de usuário (o POST não os devolve).
  LeituraParticipanteModel comNome({String? udetNome, String? udetUsuario}) => LeituraParticipanteModel(
    lparId: lparId,
    leitId: leitId,
    usuaId: usuaId,
    udetNome: udetNome ?? this.udetNome,
    udetUsuario: udetUsuario ?? this.udetUsuario,
    createdAt: createdAt,
  );
}
