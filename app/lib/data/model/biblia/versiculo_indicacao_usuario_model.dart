import 'json_reader.dart';

/// Usuário que recebe uma indicação de versículo (`biblia.versiculo_indicacao_usuario`), como devolvido por
/// `/v1/versiculo-indicacao-usuario`.
///
/// [usuaId] é o destinatário; [udetNome] e [udetUsuario] vêm do detalhe dele no GET (nulos se não houver detalhe ou
/// na resposta do POST, que devolve só o registro gravado).
class VersiculoIndicacaoUsuarioModel {
  const VersiculoIndicacaoUsuarioModel({
    required this.viusId,
    required this.vindId,
    required this.usuaId,
    this.udetNome,
    this.udetUsuario,
  });

  final int viusId;
  final int vindId;
  final int usuaId;
  final String? udetNome;
  final String? udetUsuario;

  factory VersiculoIndicacaoUsuarioModel.fromJson(Map<String, dynamic> json) => VersiculoIndicacaoUsuarioModel(
    viusId: JsonReader.inteiro(json, 'viusId', 'vius_id'),
    vindId: JsonReader.inteiro(json, 'vindId', 'vind_id'),
    usuaId: JsonReader.inteiro(json, 'usuaId', 'usua_id'),
    udetNome: JsonReader.textoOpcional(json, 'udetNome', 'udet_nome'),
    udetUsuario: JsonReader.textoOpcional(json, 'udetUsuario', 'udet_usuario'),
  );

  /// Cópia com o nome e o usuário informados (usada para completar a resposta do POST).
  VersiculoIndicacaoUsuarioModel comNome({String? udetNome, String? udetUsuario}) => VersiculoIndicacaoUsuarioModel(
    viusId: viusId,
    vindId: vindId,
    usuaId: usuaId,
    udetNome: this.udetNome ?? udetNome,
    udetUsuario: this.udetUsuario ?? udetUsuario,
  );
}
