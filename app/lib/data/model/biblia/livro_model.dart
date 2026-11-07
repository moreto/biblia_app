import 'json_reader.dart';

/// Livro da Bíblia (`GET /v1/livro`).
class LivroModel {
  const LivroModel({
    required this.livrId,
    required this.testId,
    required this.livrNome,
    required this.livrAbrev,
    required this.livrCapituloCount,
  });

  final int livrId;
  final int testId;
  final String livrNome;
  final String livrAbrev;

  /// Quantidade de capítulos do livro, informada pela API.
  final int livrCapituloCount;

  factory LivroModel.fromJson(Map<String, dynamic> json) => LivroModel(
    livrId: JsonReader.inteiro(json, 'livrId', 'livr_id'),
    testId: JsonReader.inteiro(json, 'testId', 'test_id'),
    livrNome: JsonReader.texto(json, 'livrNome', 'livr_nome'),
    livrAbrev: JsonReader.texto(json, 'livrAbrev', 'livr_abrev'),
    livrCapituloCount: JsonReader.inteiroOpcional(json, 'livrCapituloCount', 'livr_capitulo_count') ?? 0,
  );
}
