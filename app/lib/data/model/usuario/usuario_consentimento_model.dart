import '../biblia/json_reader.dart';

/// Resposta de `GET /v1/usuario-consentimento`: cada finalidade com a versão atual do termo ([termos]) e todos os
/// aceites e revogações do usuário ([historico]).
class UsuarioConsentimentoListaModel {
  const UsuarioConsentimentoListaModel({this.termos = const [], this.historico = const []});

  final List<UsuarioConsentimentoTermoModel> termos;
  final List<UsuarioConsentimentoModel> historico;

  factory UsuarioConsentimentoListaModel.fromJson(Map<String, dynamic> json) => UsuarioConsentimentoListaModel(
    termos: _lista(json['termos'], UsuarioConsentimentoTermoModel.fromJson),
    historico: _lista(json['historico'], UsuarioConsentimentoModel.fromJson),
  );

  static List<T> _lista<T>(Object? valor, T Function(Map<String, dynamic>) fromJson) => switch (valor) {
    null => const [],
    final List lista => [
      for (final item in lista)
        if (item is Map) fromJson(Map<String, dynamic>.from(item)) else throw const FormatException('campoInvalido'),
    ],
    _ => throw const FormatException('campoInvalido'),
  };
}

/// Termo de uma finalidade (`dadosReligiosos`, `termosUso`, `politicaPrivacidade`) na versão atual e se o usuário
/// o aceitou (aceite não revogado dessa versão).
class UsuarioConsentimentoTermoModel {
  const UsuarioConsentimentoTermoModel({required this.finalidade, required this.versao, this.aceito = false});

  final String finalidade;
  final String versao;
  final bool aceito;

  factory UsuarioConsentimentoTermoModel.fromJson(Map<String, dynamic> json) => UsuarioConsentimentoTermoModel(
    finalidade: JsonReader.texto(json, 'finalidade', 'ucns_finalidade'),
    versao: JsonReader.texto(json, 'versao', 'ucns_versao'),
    aceito: switch (json['aceito']) {
      null => false,
      final bool valor => valor,
      _ => throw const FormatException('campoInvalido', 'aceito'),
    },
  );

  Map<String, dynamic> toJson() => {'finalidade': finalidade, 'versao': versao, 'aceito': aceito};
}

/// Registro de `public.usuario_consentimento`: aceite do termo [ucnsVersao] da finalidade [ucnsFinalidade] em
/// [createdAt]; [ucnsRevogadoEm] é nula enquanto o aceite vale.
class UsuarioConsentimentoModel {
  const UsuarioConsentimentoModel({
    required this.ucnsId,
    this.usuaId,
    required this.ucnsFinalidade,
    required this.ucnsVersao,
    this.ucnsIp,
    this.ucnsRevogadoEm,
    this.createdAt,
    this.updatedAt,
  });

  final int ucnsId;
  final int? usuaId;
  final String ucnsFinalidade;
  final String ucnsVersao;
  final String? ucnsIp;
  final DateTime? ucnsRevogadoEm;

  /// Data do aceite.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get revogado => ucnsRevogadoEm != null;

  factory UsuarioConsentimentoModel.fromJson(Map<String, dynamic> json) => UsuarioConsentimentoModel(
    ucnsId: JsonReader.inteiro(json, 'ucnsId', 'ucns_id'),
    usuaId: JsonReader.inteiroOpcional(json, 'usuaId', 'usua_id'),
    ucnsFinalidade: JsonReader.texto(json, 'ucnsFinalidade', 'ucns_finalidade'),
    ucnsVersao: JsonReader.texto(json, 'ucnsVersao', 'ucns_versao'),
    ucnsIp: JsonReader.textoOpcional(json, 'ucnsIp', 'ucns_ip'),
    ucnsRevogadoEm: JsonReader.data(json, 'ucnsRevogadoEm', 'ucns_revogado_em')?.toLocal(),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
    updatedAt: JsonReader.data(json, 'updatedAt', 'updated_at')?.toLocal(),
  );
}

/// Corpo de `POST /v1/usuario-consentimento`: aceite do termo [ucnsVersao] da finalidade [ucnsFinalidade].
class UsuarioConsentimentoBodyModel {
  const UsuarioConsentimentoBodyModel({required this.ucnsFinalidade, required this.ucnsVersao});

  final String ucnsFinalidade;
  final String ucnsVersao;

  Map<String, dynamic> toJson() => {'ucnsFinalidade': ucnsFinalidade, 'ucnsVersao': ucnsVersao};
}
