import '../biblia/json_reader.dart';

/// Usuário encontrado por `GET /v1/usuario/busca`: só o id, o nome completo e o nome de usuário (sem e-mail).
class UsuarioResumoModel {
  const UsuarioResumoModel({required this.usuaId, this.udetNome, this.udetUsuario});

  final int usuaId;
  final String? udetNome;
  final String? udetUsuario;

  factory UsuarioResumoModel.fromJson(Map<String, dynamic> json) => UsuarioResumoModel(
    usuaId: JsonReader.inteiro(json, 'usuaId', 'usua_id'),
    udetNome: JsonReader.textoOpcional(json, 'udetNome', 'udet_nome'),
    udetUsuario: JsonReader.textoOpcional(json, 'udetUsuario', 'udet_usuario'),
  );
}
