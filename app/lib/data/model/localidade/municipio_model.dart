import '../biblia/json_reader.dart';

/// Município de um estado (`GET /v1/municipio/:estaId`, `public.municipio`).
class MunicipioModel {
  const MunicipioModel({required this.muniId, required this.muniNome, required this.estaId});

  final int muniId;
  final String muniNome;
  final int estaId;

  factory MunicipioModel.fromJson(Map<String, dynamic> json) => MunicipioModel(
    muniId: JsonReader.inteiro(json, 'muniId', 'muni_id'),
    muniNome: JsonReader.texto(json, 'muniNome', 'muni_nome'),
    estaId: JsonReader.inteiro(json, 'estaId', 'esta_id'),
  );
}
