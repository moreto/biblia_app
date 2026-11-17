import '../biblia/json_reader.dart';

/// Chamado do Fale Conosco visto pelo solicitante (`GET /v1/fale-conosco/meus` e `/meus/:fconId`), sem os dados
/// internos do atendimento. Categoria, situação e origem são `cite_chave` das configurações `faleConoscoCategoria`,
/// `faleConoscoStatus` e `faleConoscoOrigem`. [interacoes] só vem no detalhe (`/meus/:fconId`).
class FaleConoscoModel {
  const FaleConoscoModel({
    required this.fconId,
    required this.fconProtocolo,
    required this.fconAssunto,
    required this.fconMensagem,
    required this.fconCategoria,
    required this.fconStatus,
    this.fconOrigem,
    this.fconPrimeiraRespostaEm,
    this.fconFechadoEm,
    this.createdAt,
    this.updatedAt,
    this.interacoes = const [],
  });

  final int fconId;
  final String fconProtocolo;
  final String fconAssunto;
  final String fconMensagem;
  final int fconCategoria;
  final int fconStatus;
  final int? fconOrigem;
  final DateTime? fconPrimeiraRespostaEm;
  final DateTime? fconFechadoEm;

  /// Data de envio.
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<FaleConoscoInteracaoModel> interacoes;

  /// Fechado pelo atendimento: não aceita mais mensagens do solicitante.
  bool get fechado => fconFechadoEm != null;

  factory FaleConoscoModel.fromJson(Map<String, dynamic> json) => FaleConoscoModel(
    fconId: JsonReader.inteiro(json, 'fconId', 'fcon_id'),
    fconProtocolo: JsonReader.texto(json, 'fconProtocolo', 'fcon_protocolo'),
    fconAssunto: JsonReader.texto(json, 'fconAssunto', 'fcon_assunto'),
    fconMensagem: JsonReader.texto(json, 'fconMensagem', 'fcon_mensagem'),
    fconCategoria: JsonReader.inteiro(json, 'fconCategoria', 'fcon_categoria'),
    fconStatus: JsonReader.inteiro(json, 'fconStatus', 'fcon_status'),
    fconOrigem: JsonReader.inteiroOpcional(json, 'fconOrigem', 'fcon_origem'),
    fconPrimeiraRespostaEm: JsonReader.data(json, 'fconPrimeiraRespostaEm', 'fcon_primeira_resposta_em')?.toLocal(),
    fconFechadoEm: JsonReader.data(json, 'fconFechadoEm', 'fcon_fechado_em')?.toLocal(),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
    updatedAt: JsonReader.data(json, 'updatedAt', 'updated_at')?.toLocal(),
    interacoes: switch (json['interacoes']) {
      null => const [],
      final List lista => [
        for (final item in lista)
          if (item is Map)
            FaleConoscoInteracaoModel.fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('campoInvalido', 'interacoes'),
      ],
      _ => throw const FormatException('campoInvalido', 'interacoes'),
    },
  );
}

/// Interação visível ao solicitante: resposta do atendimento ou mensagem do próprio solicitante ([fcinSolicitante]).
class FaleConoscoInteracaoModel {
  const FaleConoscoInteracaoModel({
    required this.fcinId,
    required this.fcinTexto,
    this.fcinStatus,
    this.createdAt,
    this.fcinSolicitante = false,
  });

  final int fcinId;
  final String fcinTexto;

  /// Situação do chamado depois da interação.
  final int? fcinStatus;
  final DateTime? createdAt;

  /// Escrita pelo solicitante (senão, pelo atendimento).
  final bool fcinSolicitante;

  factory FaleConoscoInteracaoModel.fromJson(Map<String, dynamic> json) => FaleConoscoInteracaoModel(
    fcinId: JsonReader.inteiro(json, 'fcinId', 'fcin_id'),
    fcinTexto: JsonReader.texto(json, 'fcinTexto', 'fcin_texto'),
    fcinStatus: JsonReader.inteiroOpcional(json, 'fcinStatus', 'fcin_status'),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
    fcinSolicitante: switch (json['fcinSolicitante'] ?? json['fcin_solicitante']) {
      null => false,
      final bool valor => valor,
      _ => throw const FormatException('campoInvalido', 'fcinSolicitante'),
    },
  );
}

/// Resposta do envio (`POST /v1/fale-conosco`): id e protocolo do chamado.
class FaleConoscoEnvioModel {
  const FaleConoscoEnvioModel({required this.fconId, required this.fconProtocolo, this.createdAt});

  final int fconId;
  final String fconProtocolo;
  final DateTime? createdAt;

  factory FaleConoscoEnvioModel.fromJson(Map<String, dynamic> json) => FaleConoscoEnvioModel(
    fconId: JsonReader.inteiro(json, 'fconId', 'fcon_id'),
    fconProtocolo: JsonReader.texto(json, 'fconProtocolo', 'fcon_protocolo'),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
  );
}

/// Corpo de `POST /v1/fale-conosco`. Categoria e origem são `cite_chave` (inteiros) das configurações.
class FaleConoscoBodyModel {
  const FaleConoscoBodyModel({
    required this.fconNome,
    required this.fconEmail,
    this.fconTelefone,
    required this.fconAssunto,
    required this.fconMensagem,
    required this.fconCategoria,
    required this.fconOrigem,
  });

  final String fconNome;
  final String fconEmail;
  final String? fconTelefone;
  final String fconAssunto;
  final String fconMensagem;
  final int fconCategoria;
  final int fconOrigem;

  Map<String, dynamic> toJson() => {
    'fconNome': fconNome,
    'fconEmail': fconEmail,
    'fconTelefone': fconTelefone,
    'fconAssunto': fconAssunto,
    'fconMensagem': fconMensagem,
    'fconCategoria': fconCategoria,
    'fconOrigem': fconOrigem,
  };
}
