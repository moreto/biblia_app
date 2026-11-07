import 'json_reader.dart';

/// Indicação de um versículo por um usuário (`biblia.versiculo_indicacao`), como devolvida por
/// `/v1/versiculo-indicacao`.
///
/// [vindId] é nulo enquanto a indicação não foi gravada (corpo do POST).
class VersiculoIndicacaoModel {
  const VersiculoIndicacaoModel({this.vindId, required this.versId, this.usuaId, this.vindComentario});

  final int? vindId;
  final int versId;

  /// Dono da indicação. Na gravação a API usa o usuário do token e ignora o valor enviado.
  final int? usuaId;
  final String? vindComentario;

  factory VersiculoIndicacaoModel.fromJson(Map<String, dynamic> json) => VersiculoIndicacaoModel(
    vindId: JsonReader.inteiroOpcional(json, 'vindId', 'vind_id'),
    versId: JsonReader.inteiro(json, 'versId', 'vers_id'),
    usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
    vindComentario: JsonReader.textoOpcional(json, 'vindComentario', 'vind_comentario'),
  );

  /// Corpo do POST/PUT. Campos nulos (como [vindId] numa inclusão) são removidos pelo DioProvider.
  Map<String, dynamic> toJson() => {'vindId': vindId, 'versId': versId, 'vindComentario': vindComentario};
}
