import 'json_reader.dart';

/// Indicação de versículo recebida pelo usuário logado (`GET /v1/versiculo-indicacao-usuario/recebidas`): quando,
/// o versículo (com versão, livro, capítulo e número para abrir na leitura), o comentário e quem indicou (sem
/// e-mail).
class VersiculoIndicadoModel {
  const VersiculoIndicadoModel({
    required this.viusId,
    required this.vindId,
    this.indicadoEm,
    this.vindComentario,
    required this.versId,
    required this.versNumero,
    required this.versTexto,
    required this.versaId,
    this.versaCodigo,
    this.versaNome,
    required this.livrId,
    required this.capiNumero,
    this.livrNome,
    this.versReferencia,
    this.indicadorId,
    this.indicadorNome,
    this.indicadorUsuario,
  });

  final int viusId;
  final int vindId;

  /// Quando o usuário recebeu a indicação.
  final DateTime? indicadoEm;
  final String? vindComentario;
  final int versId;
  final int versNumero;
  final String versTexto;
  final int versaId;
  final String? versaCodigo;
  final String? versaNome;
  final int livrId;
  final int capiNumero;
  final String? livrNome;

  /// Ex.: "Mateus 6:34".
  final String? versReferencia;
  final int? indicadorId;
  final String? indicadorNome;
  final String? indicadorUsuario;

  factory VersiculoIndicadoModel.fromJson(Map<String, dynamic> json) => VersiculoIndicadoModel(
    viusId: JsonReader.inteiro(json, 'viusId', 'vius_id'),
    vindId: JsonReader.inteiro(json, 'vindId', 'vind_id'),
    indicadoEm: JsonReader.data(json, 'indicadoEm', 'indicado_em')?.toLocal(),
    vindComentario: JsonReader.textoOpcional(json, 'vindComentario', 'vind_comentario'),
    versId: JsonReader.inteiro(json, 'versId', 'vers_id'),
    versNumero: JsonReader.inteiro(json, 'versNumero', 'vers_numero'),
    versTexto: JsonReader.texto(json, 'versTexto', 'vers_texto'),
    versaId: JsonReader.inteiro(json, 'versaId', 'versa_id'),
    versaCodigo: JsonReader.textoOpcional(json, 'versaCodigo', 'versa_codigo'),
    versaNome: JsonReader.textoOpcional(json, 'versaNome', 'versa_nome'),
    livrId: JsonReader.inteiro(json, 'livrId', 'livr_id'),
    capiNumero: JsonReader.inteiro(json, 'capiNumero', 'capi_numero'),
    livrNome: JsonReader.textoOpcional(json, 'livrNome', 'livr_nome'),
    versReferencia: JsonReader.textoOpcional(json, 'versReferencia', 'vers_referencia'),
    indicadorId: JsonReader.inteiroOpcional(json, 'indicadorId', 'indicador_id'),
    indicadorNome: JsonReader.textoOpcional(json, 'indicadorNome', 'indicador_nome'),
    indicadorUsuario: JsonReader.textoOpcional(json, 'indicadorUsuario', 'indicador_usuario'),
  );
}
