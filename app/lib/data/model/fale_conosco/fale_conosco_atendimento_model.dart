import '../biblia/json_reader.dart';

/// Chamado do Fale Conosco visto pelo atendimento (`GET /v1/fale-conosco` e `/v1/fale-conosco/:fconId`, `PUT`):
/// dados de contato, classificação (categoria, prioridade, situação e origem são `cite_chave` das configurações
/// `faleConoscoCategoria`, `faleConoscoPrioridade`, `faleConoscoStatus` e `faleConoscoOrigem`), responsável, IP,
/// navegador e o tempo até a primeira resposta ([fconTempoResposta], em segundos).
class FaleConoscoAtendimentoModel {
  const FaleConoscoAtendimentoModel({
    required this.fconId,
    required this.fconProtocolo,
    this.usuaId,
    required this.fconNome,
    required this.fconEmail,
    this.fconTelefone,
    required this.fconAssunto,
    required this.fconMensagem,
    required this.fconCategoria,
    required this.fconPrioridade,
    required this.fconStatus,
    this.fconOrigem,
    this.fconResponsavelId,
    this.fconResponsavelNome,
    this.fconPrimeiraRespostaEm,
    this.fconFechadoEm,
    this.fconPaginaOrigem,
    this.fconIp,
    this.fconUserAgent,
    this.createdAt,
    this.updatedAt,
    this.fconTempoResposta,
  });

  final int fconId;
  final String fconProtocolo;

  /// Usuário que enviou, se estava logado.
  final int? usuaId;
  final String fconNome;
  final String fconEmail;
  final String? fconTelefone;
  final String fconAssunto;
  final String fconMensagem;
  final int fconCategoria;
  final int fconPrioridade;
  final int fconStatus;
  final int? fconOrigem;
  final int? fconResponsavelId;
  final String? fconResponsavelNome;
  final DateTime? fconPrimeiraRespostaEm;
  final DateTime? fconFechadoEm;
  final String? fconPaginaOrigem;
  final String? fconIp;
  final String? fconUserAgent;

  /// Data de envio.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Segundos entre o envio e a primeira resposta; nulo sem resposta.
  final int? fconTempoResposta;

  bool get fechado => fconFechadoEm != null;

  factory FaleConoscoAtendimentoModel.fromJson(Map<String, dynamic> json) => FaleConoscoAtendimentoModel(
    fconId: JsonReader.inteiro(json, 'fconId', 'fcon_id'),
    fconProtocolo: JsonReader.texto(json, 'fconProtocolo', 'fcon_protocolo'),
    usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
    fconNome: JsonReader.texto(json, 'fconNome', 'fcon_nome'),
    fconEmail: JsonReader.texto(json, 'fconEmail', 'fcon_email'),
    fconTelefone: JsonReader.textoOpcional(json, 'fconTelefone', 'fcon_telefone'),
    fconAssunto: JsonReader.texto(json, 'fconAssunto', 'fcon_assunto'),
    fconMensagem: JsonReader.texto(json, 'fconMensagem', 'fcon_mensagem'),
    fconCategoria: JsonReader.inteiro(json, 'fconCategoria', 'fcon_categoria'),
    fconPrioridade: JsonReader.inteiro(json, 'fconPrioridade', 'fcon_prioridade'),
    fconStatus: JsonReader.inteiro(json, 'fconStatus', 'fcon_status'),
    fconOrigem: JsonReader.inteiroOpcional(json, 'fconOrigem', 'fcon_origem'),
    fconResponsavelId: JsonReader.inteiroOpcional(json, 'fconResponsavelId', 'fcon_responsavel_id'),
    fconResponsavelNome: JsonReader.textoOpcional(json, 'fconResponsavelNome', 'fcon_responsavel_nome'),
    fconPrimeiraRespostaEm: JsonReader.data(json, 'fconPrimeiraRespostaEm', 'fcon_primeira_resposta_em')?.toLocal(),
    fconFechadoEm: JsonReader.data(json, 'fconFechadoEm', 'fcon_fechado_em')?.toLocal(),
    fconPaginaOrigem: JsonReader.textoOpcional(json, 'fconPaginaOrigem', 'fcon_pagina_origem'),
    fconIp: JsonReader.textoOpcional(json, 'fconIp', 'fcon_ip'),
    fconUserAgent: JsonReader.textoOpcional(json, 'fconUserAgent', 'fcon_user_agent'),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
    updatedAt: JsonReader.data(json, 'updatedAt', 'updated_at')?.toLocal(),
    fconTempoResposta: JsonReader.inteiroOpcional(json, 'fconTempoResposta', 'fcon_tempo_resposta'),
  );
}

/// Interação do chamado vista pelo atendimento (`GET /v1/fale-conosco-interacao/:fconId`), inclusive as notas
/// internas ([fcinInterna], não vistas pelo solicitante), com o nome do autor ([udetNome]).
class FaleConoscoAtendimentoInteracaoModel {
  const FaleConoscoAtendimentoInteracaoModel({
    required this.fcinId,
    this.fconId,
    this.usuaId,
    required this.fcinTexto,
    this.fcinInterna = false,
    this.fcinStatus,
    this.createdAt,
    this.udetNome,
  });

  final int fcinId;
  final int? fconId;

  /// Autor; nulo se o usuário não existir mais.
  final int? usuaId;
  final String fcinTexto;
  final bool fcinInterna;

  /// Situação do chamado depois da interação.
  final int? fcinStatus;
  final DateTime? createdAt;
  final String? udetNome;

  factory FaleConoscoAtendimentoInteracaoModel.fromJson(Map<String, dynamic> json) =>
      FaleConoscoAtendimentoInteracaoModel(
        fcinId: JsonReader.inteiro(json, 'fcinId', 'fcin_id'),
        fconId: JsonReader.inteiroOpcional(json, 'fconId', 'fcon_id'),
        usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
        fcinTexto: JsonReader.texto(json, 'fcinTexto', 'fcin_texto'),
        fcinInterna: switch (json['fcinInterna'] ?? json['fcin_interna']) {
          null => false,
          final bool valor => valor,
          _ => throw const FormatException('campoInvalido', 'fcinInterna'),
        },
        fcinStatus: JsonReader.inteiroOpcional(json, 'fcinStatus', 'fcin_status'),
        createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
        udetNome: JsonReader.textoOpcional(json, 'udetNome', 'udet_nome'),
      );
}

/// Corpo de `PUT /v1/fale-conosco`: a API grava todos os campos, então o chamado vai inteiro (responsável nulo deixa
/// o chamado sem responsável). [fconFechado]: `true` fecha, `false` reabre, nulo mantém.
class FaleConoscoAtendimentoBodyModel {
  const FaleConoscoAtendimentoBodyModel({
    required this.fconId,
    required this.fconCategoria,
    required this.fconPrioridade,
    required this.fconStatus,
    this.fconResponsavelId,
    this.fconFechado,
  });

  final int fconId;
  final int fconCategoria;
  final int fconPrioridade;
  final int fconStatus;
  final int? fconResponsavelId;
  final bool? fconFechado;

  /// O responsável vai sempre (nulo = sem responsável); `fconFechado` só quando informado.
  Map<String, dynamic> toJson() => {
    'fconId': fconId,
    'fconCategoria': fconCategoria,
    'fconPrioridade': fconPrioridade,
    'fconStatus': fconStatus,
    'fconResponsavelId': fconResponsavelId,
    'fconFechado': ?fconFechado,
  };
}

/// Corpo de `POST /v1/fale-conosco-interacao`: resposta ao solicitante ou nota interna, com nova situação opcional.
class FaleConoscoAtendimentoInteracaoBodyModel {
  const FaleConoscoAtendimentoInteracaoBodyModel({
    required this.fconId,
    required this.fcinTexto,
    this.fcinInterna = false,
    this.fconStatus,
  });

  final int fconId;
  final String fcinTexto;
  final bool fcinInterna;
  final int? fconStatus;

  Map<String, dynamic> toJson() => {
    'fconId': fconId,
    'fcinTexto': fcinTexto,
    'fcinInterna': fcinInterna,
    'fconStatus': ?fconStatus,
  };
}

/// Filtros da fila (`GET /v1/fale-conosco?fconStatus=&fconCategoria=&fconPrioridade=&fconResponsavelId=`).
class FaleConoscoAtendimentoFiltroModel {
  const FaleConoscoAtendimentoFiltroModel({
    this.fconStatus,
    this.fconCategoria,
    this.fconPrioridade,
    this.fconResponsavelId,
  });

  final int? fconStatus;
  final int? fconCategoria;
  final int? fconPrioridade;
  final int? fconResponsavelId;

  bool get vazio => fconStatus == null && fconCategoria == null && fconPrioridade == null && fconResponsavelId == null;

  Map<String, Object> toQuery() => {
    'fconStatus': ?fconStatus,
    'fconCategoria': ?fconCategoria,
    'fconPrioridade': ?fconPrioridade,
    'fconResponsavelId': ?fconResponsavelId,
  };
}
