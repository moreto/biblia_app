import 'package:intl/intl.dart';

import '../biblia/json_reader.dart';

/// Item da agenda de um grupo de leitura (`biblia.leitura_agenda`; `/v1/leitura-agenda`).
///
/// A API grava data e hora sem fuso: [lageDataHora] vai como `AAAA-MM-DDTHH:MM:SS` (hora local) e
/// [lageHoraAtividade] como `HH:MM[:SS]`, guardada como texto. [lageRepete], [lageFimRepete] e [lageLembrete] são o
/// `cite_chave` de um item das configurações `agendaRepeticao`, `agendaFimRepeticao` e `agendaLembrete`.
class LeituraAgendaModel {
  const LeituraAgendaModel({
    this.lageId,
    required this.leitId,
    this.lageTitulo,
    this.lageTexto,
    this.lageDataHora,
    this.lageHoraAtividade,
    this.lageRepete,
    this.lageFimRepete,
    this.lageLembrete,
  });

  /// Nulo enquanto o item não foi gravado.
  final int? lageId;
  final int leitId;
  final String? lageTitulo;
  final String? lageTexto;
  final DateTime? lageDataHora;
  final String? lageHoraAtividade;
  final int? lageRepete;
  final int? lageFimRepete;
  final int? lageLembrete;

  static final _formatoDataHora = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  factory LeituraAgendaModel.fromJson(Map<String, dynamic> json) => LeituraAgendaModel(
    lageId: JsonReader.inteiroOpcional(json, 'lageId', 'lage_id'),
    leitId: JsonReader.inteiro(json, 'leitId', 'leit_id'),
    lageTitulo: JsonReader.textoOpcional(json, 'lageTitulo', 'lage_titulo'),
    lageTexto: JsonReader.textoOpcional(json, 'lageTexto', 'lage_texto'),
    lageDataHora: JsonReader.data(json, 'lageDataHora', 'lage_data_hora')?.toLocal(),
    lageHoraAtividade: JsonReader.textoOpcional(json, 'lageHoraAtividade', 'lage_hora_atividade'),
    lageRepete: JsonReader.inteiroOpcional(json, 'lageRepete', 'lage_repete'),
    lageFimRepete: JsonReader.inteiroOpcional(json, 'lageFimRepete', 'lage_fim_repete'),
    lageLembrete: JsonReader.inteiroOpcional(json, 'lageLembrete', 'lage_lembrete'),
  );

  /// Corpo do POST/PUT ([lageId] só no PUT). Campos nulos são removidos pelo DioProvider e a API grava `null` no
  /// que não vier, então limpar um campo funciona.
  Map<String, dynamic> toJson() => {
    'lageId': lageId,
    'leitId': leitId,
    'lageTitulo': lageTitulo,
    'lageTexto': lageTexto,
    'lageDataHora': lageDataHora == null ? null : _formatoDataHora.format(lageDataHora!),
    'lageHoraAtividade': lageHoraAtividade,
    'lageRepete': lageRepete,
    'lageFimRepete': lageFimRepete,
    'lageLembrete': lageLembrete,
  };
}
