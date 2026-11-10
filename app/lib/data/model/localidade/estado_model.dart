import '../biblia/json_reader.dart';

/// Estado (`GET /v1/estado`, `public.estado`).
class EstadoModel {
  const EstadoModel({required this.estaId, required this.estaNome, required this.estaSigla});

  final int estaId;
  final String estaNome;
  final String estaSigla;

  factory EstadoModel.fromJson(Map<String, dynamic> json) => EstadoModel(
    estaId: JsonReader.inteiro(json, 'estaId', 'esta_id'),
    estaNome: JsonReader.texto(json, 'estaNome', 'esta_nome'),
    estaSigla: JsonReader.texto(json, 'estaSigla', 'esta_sigla'),
  );
}
