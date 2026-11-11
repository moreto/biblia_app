import '../biblia/json_reader.dart';

/// Tipo de mensagem (`GET /v1/mensagem-tipo`). O tipo 0 é o de sistema (mensagens geradas pela API).
class MensagemTipoModel {
  const MensagemTipoModel({required this.mtipId, required this.mtipTipo});

  final int mtipId;
  final String mtipTipo;

  factory MensagemTipoModel.fromJson(Map<String, dynamic> json) => MensagemTipoModel(
    mtipId: JsonReader.inteiro(json, 'mtipId', 'mtip_id'),
    mtipTipo: JsonReader.texto(json, 'mtipTipo', 'mtip_tipo'),
  );
}
