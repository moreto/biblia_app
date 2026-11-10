import 'json_reader.dart';

/// Renomado (`biblia.renomado`), como devolvido por `/v1/renomado`.
///
/// [renoSeq] é a ordem de exibição; nulo vai para o fim da lista.
class RenomadoModel {
  const RenomadoModel({required this.renoId, required this.renoNome, this.renoTexto, this.renoSeq});

  final int renoId;

  /// Nome (até 60 caracteres).
  final String renoNome;

  /// Texto de apresentação (até 512 caracteres).
  final String? renoTexto;
  final int? renoSeq;

  factory RenomadoModel.fromJson(Map<String, dynamic> json) => RenomadoModel(
    renoId: JsonReader.inteiro(json, 'renoId', 'reno_id'),
    renoNome: JsonReader.texto(json, 'renoNome', 'reno_nome'),
    renoTexto: JsonReader.textoOpcional(json, 'renoTexto', 'reno_texto'),
    renoSeq: JsonReader.inteiroOpcional(json, 'renoSeq', 'reno_seq'),
  );

  Map<String, dynamic> toJson() => {'renoId': renoId, 'renoNome': renoNome, 'renoTexto': renoTexto, 'renoSeq': renoSeq};

  RenomadoModel copyWith({String? renoNome, String? Function()? renoTexto}) => RenomadoModel(
    renoId: renoId,
    renoNome: renoNome ?? this.renoNome,
    renoTexto: renoTexto != null ? renoTexto() : this.renoTexto,
    renoSeq: renoSeq,
  );
}
