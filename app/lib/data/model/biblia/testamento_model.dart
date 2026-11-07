import 'json_reader.dart';

/// Testamento (`GET /v1/testamento`).
class TestamentoModel {
  const TestamentoModel({required this.testId, required this.testNome});

  final int testId;
  final String testNome;

  factory TestamentoModel.fromJson(Map<String, dynamic> json) => TestamentoModel(
    testId: JsonReader.inteiro(json, 'testId', 'test_id'),
    testNome: JsonReader.texto(json, 'testNome', 'test_nome'),
  );
}
