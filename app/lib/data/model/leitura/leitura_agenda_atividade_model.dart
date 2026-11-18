import '../biblia/json_reader.dart';

/// Atividade de um item da agenda (`biblia.leitura_agenda_atividade`; `/v1/leitura-agenda-atividade`).
///
/// [livrId], [musiId] e [oracId] são opcionais e apontam para um livro da Bíblia, uma música e uma oração.
class LeituraAgendaAtividadeModel {
  const LeituraAgendaAtividadeModel({
    this.laatId,
    required this.lageId,
    this.livrId,
    this.musiId,
    this.oracId,
    this.laatSeq = 0,
    this.laatTexto,
    this.laatConcluida = false,
  });

  /// Nulo enquanto a atividade não foi gravada.
  final int? laatId;
  final int lageId;
  final int? livrId;
  final int? musiId;
  final int? oracId;

  /// Ordem da atividade no item da agenda.
  final int laatSeq;
  final String? laatTexto;
  final bool laatConcluida;

  factory LeituraAgendaAtividadeModel.fromJson(Map<String, dynamic> json) => LeituraAgendaAtividadeModel(
    laatId: JsonReader.inteiroOpcional(json, 'laatId', 'laat_id'),
    lageId: JsonReader.inteiro(json, 'lageId', 'lage_id'),
    livrId: JsonReader.inteiroOpcional(json, 'livrId', 'livr_id'),
    musiId: JsonReader.inteiroOpcional(json, 'musiId', 'musi_id'),
    oracId: JsonReader.inteiroOpcional(json, 'oracId', 'orac_id'),
    laatSeq: JsonReader.inteiroOpcional(json, 'laatSeq', 'laat_seq') ?? 0,
    laatTexto: JsonReader.textoOpcional(json, 'laatTexto', 'laat_texto'),
    laatConcluida: switch (json['laatConcluida'] ?? json['laat_concluida']) {
      null => false,
      final bool valor => valor,
      _ => throw const FormatException('campoInvalido', 'laatConcluida'),
    },
  );

  /// Corpo do POST/PUT (campos nulos são removidos pelo DioProvider; a API grava `null` no que não vier).
  Map<String, dynamic> toJson() => {
    'laatId': laatId,
    'lageId': lageId,
    'livrId': livrId,
    'musiId': musiId,
    'oracId': oracId,
    'laatSeq': laatSeq,
    'laatTexto': laatTexto,
    'laatConcluida': laatConcluida,
  };

  /// Cópia com outro [laatConcluida].
  LeituraAgendaAtividadeModel comConcluida(bool concluida) => LeituraAgendaAtividadeModel(
    laatId: laatId,
    lageId: lageId,
    livrId: livrId,
    musiId: musiId,
    oracId: oracId,
    laatSeq: laatSeq,
    laatTexto: laatTexto,
    laatConcluida: concluida,
  );
}
