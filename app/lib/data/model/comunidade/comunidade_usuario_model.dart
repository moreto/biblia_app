import '../biblia/json_reader.dart';

/// Usuário vinculado a uma comunidade (`biblia.comunidade_usuario`), como devolvido por
/// `/v1/comunidade-usuario/:comuId`.
///
/// [udetNome] e [udetUsuario] vêm de `public.usuario_detalhe` (nulos se a API não os devolver); não vão no corpo.
class ComunidadeUsuarioModel {
  const ComunidadeUsuarioModel({
    this.cusuId,
    required this.comuId,
    required this.usuaId,
    this.cusuAtivo = true,
    this.udetNome,
    this.udetUsuario,
  });

  /// Nulo enquanto o vínculo não foi gravado.
  final int? cusuId;
  final int comuId;
  final int usuaId;
  final bool cusuAtivo;
  final String? udetNome;
  final String? udetUsuario;

  factory ComunidadeUsuarioModel.fromJson(Map<String, dynamic> json) {
    final ativo = json['cusuAtivo'] ?? json['cusu_ativo'];
    return ComunidadeUsuarioModel(
      cusuId: JsonReader.inteiroOpcional(json, 'cusuId', 'cusu_id'),
      comuId: JsonReader.inteiro(json, 'comuId', 'comu_id'),
      usuaId: JsonReader.inteiro(json, 'usuaId', 'usua_id'),
      cusuAtivo: switch (ativo) {
        null => true,
        final bool valor => valor,
        _ => throw FormatException('campoInvalido', 'cusuAtivo'),
      },
      udetNome: JsonReader.textoOpcional(json, 'udetNome', 'udet_nome'),
      udetUsuario: JsonReader.textoOpcional(json, 'udetUsuario', 'udet_usuario'),
    );
  }

  /// Cópia com outro [cusuAtivo] e, se informados, o nome e o nome de usuário.
  ComunidadeUsuarioModel copiar({bool? cusuAtivo, String? udetNome, String? udetUsuario}) => ComunidadeUsuarioModel(
    cusuId: cusuId,
    comuId: comuId,
    usuaId: usuaId,
    cusuAtivo: cusuAtivo ?? this.cusuAtivo,
    udetNome: udetNome ?? this.udetNome,
    udetUsuario: udetUsuario ?? this.udetUsuario,
  );

  /// Corpo do POST/PUT (campos nulos são removidos pelo DioProvider).
  Map<String, dynamic> toJson() => {'cusuId': cusuId, 'comuId': comuId, 'usuaId': usuaId, 'cusuAtivo': cusuAtivo};
}
