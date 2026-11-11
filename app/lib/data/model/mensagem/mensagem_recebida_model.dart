import '../biblia/json_reader.dart';

/// Mensagem recebida pelo usuário logado (`GET /v1/mensagem-usuario/recebidas`): situação para ele (lida,
/// arquivada, resposta), tipo, título, texto e remetente.
///
/// Mensagens de sistema ([mtipId] = [kTipoSistema]) são os e-mails enviados ao usuário; nelas o remetente é o
/// próprio usuário.
class MensagemRecebidaModel {
  const MensagemRecebidaModel({
    required this.musuId,
    required this.mensId,
    this.musuLida = false,
    this.musuLidaEm,
    this.musuArquivada = false,
    this.musuResposta,
    this.musuRespondida = false,
    this.recebidaEm,
    required this.mtipId,
    this.mtipTipo,
    required this.mensTitulo,
    required this.mensTexto,
    this.remetenteId,
    this.remetenteNome,
    this.remetenteUsuario,
  });

  /// Tipo das mensagens de sistema (`public.mensagem_tipo`).
  static const kTipoSistema = 0;

  final int musuId;
  final int mensId;
  final bool musuLida;
  final DateTime? musuLidaEm;
  final bool musuArquivada;
  final String? musuResposta;
  final bool musuRespondida;
  final DateTime? recebidaEm;
  final int mtipId;

  /// Nome do tipo ("Sistema", "Usuário"); nulo se a API não devolver.
  final String? mtipTipo;
  final String mensTitulo;
  final String mensTexto;
  final int? remetenteId;
  final String? remetenteNome;
  final String? remetenteUsuario;

  bool get sistema => mtipId == kTipoSistema;

  factory MensagemRecebidaModel.fromJson(Map<String, dynamic> json) => MensagemRecebidaModel(
    musuId: JsonReader.inteiro(json, 'musuId', 'musu_id'),
    mensId: JsonReader.inteiro(json, 'mensId', 'mens_id'),
    musuLida: _booleano(json, 'musuLida', 'musu_lida'),
    musuLidaEm: JsonReader.data(json, 'musuLidaEm', 'musu_lida_em')?.toLocal(),
    musuArquivada: _booleano(json, 'musuArquivada', 'musu_arquivada'),
    musuResposta: JsonReader.textoOpcional(json, 'musuResposta', 'musu_resposta'),
    musuRespondida: _booleano(json, 'musuRespondida', 'musu_respondida'),
    recebidaEm: JsonReader.data(json, 'recebidaEm', 'recebida_em')?.toLocal(),
    mtipId: JsonReader.inteiro(json, 'mtipId', 'mtip_id'),
    mtipTipo: JsonReader.textoOpcional(json, 'mtipTipo', 'mtip_tipo'),
    mensTitulo: JsonReader.texto(json, 'mensTitulo', 'mens_titulo'),
    mensTexto: JsonReader.texto(json, 'mensTexto', 'mens_texto'),
    remetenteId: JsonReader.inteiroOpcional(json, 'remetenteId', 'remetente_id'),
    remetenteNome: JsonReader.textoOpcional(json, 'remetenteNome', 'remetente_nome'),
    remetenteUsuario: JsonReader.textoOpcional(json, 'remetenteUsuario', 'remetente_usuario'),
  );

  /// Cópia com a situação devolvida pelo PUT (`musuLida`, `musuLidaEm`, `musuArquivada`, `musuResposta`,
  /// `musuRespondida`); o resto da mensagem é mantido.
  MensagemRecebidaModel comSituacao(Map<String, dynamic> json) => MensagemRecebidaModel(
    musuId: musuId,
    mensId: mensId,
    musuLida: _booleanoOpcional(json, 'musuLida', 'musu_lida') ?? musuLida,
    musuLidaEm: (json.containsKey('musuLidaEm') || json.containsKey('musu_lida_em'))
        ? JsonReader.data(json, 'musuLidaEm', 'musu_lida_em')?.toLocal()
        : musuLidaEm,
    musuArquivada: _booleanoOpcional(json, 'musuArquivada', 'musu_arquivada') ?? musuArquivada,
    musuResposta: JsonReader.textoOpcional(json, 'musuResposta', 'musu_resposta') ?? musuResposta,
    musuRespondida: _booleanoOpcional(json, 'musuRespondida', 'musu_respondida') ?? musuRespondida,
    recebidaEm: recebidaEm,
    mtipId: mtipId,
    mtipTipo: mtipTipo,
    mensTitulo: mensTitulo,
    mensTexto: mensTexto,
    remetenteId: remetenteId,
    remetenteNome: remetenteNome,
    remetenteUsuario: remetenteUsuario,
  );

  static bool _booleano(Map<String, dynamic> json, String camel, String snake) =>
      _booleanoOpcional(json, camel, snake) ?? false;

  static bool? _booleanoOpcional(Map<String, dynamic> json, String camel, String snake) =>
      switch (json[camel] ?? json[snake]) {
        null => null,
        final bool valor => valor,
        _ => throw FormatException('campoInvalido', camel),
      };
}
