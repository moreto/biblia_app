import '../biblia/json_reader.dart';

/// Configuração do usuário do token (`public.usuario_configuracao`, uma por usuário; `/v1/usuario-configuracao`).
///
/// A coluna e o campo da API de [quantidadeLogsNotificacao] têm o nome com erro de digitação
/// (`uconQuantidadeLogsNotificacacao` / `ucon_quantidade_logs_notificacacao`); o model lê e grava com esse nome.
/// [uconId] é nulo enquanto o usuário não tiver configuração gravada.
class UsuarioConfiguracaoModel {
  const UsuarioConfiguracaoModel({
    this.uconId,
    required this.emailVersiculo,
    required this.emailComunidade,
    required this.emailLeitura,
    required this.emailFaleConosco,
    required this.leituraAberto,
    required this.quantidadeLogsAcesso,
    required this.quantidadeLogsNotificacao,
    this.createdAt,
    this.updateAt,
  });

  final int? uconId;
  final bool emailVersiculo;
  final bool emailComunidade;
  final bool emailLeitura;
  final bool emailFaleConosco;
  final bool leituraAberto;
  final int quantidadeLogsAcesso;
  final int quantidadeLogsNotificacao;
  final DateTime? createdAt;
  final DateTime? updateAt;

  /// Aceita camelCase ou snake_case; datas em hora local. Campo booleano ou inteiro ausente ou inválido lança
  /// [FormatException].
  factory UsuarioConfiguracaoModel.fromJson(Map<String, dynamic> json) => UsuarioConfiguracaoModel(
    uconId: JsonReader.inteiroOpcional(json, 'uconId', 'ucon_id'),
    emailVersiculo: _booleano(json, 'uconEmailVersiculo', 'ucon_email_versiculo'),
    emailComunidade: _booleano(json, 'uconEmailComunidade', 'ucon_email_comunidade'),
    emailLeitura: _booleano(json, 'uconEmailLeitura', 'ucon_email_leitura'),
    emailFaleConosco: _booleano(json, 'uconEmailFaleConosco', 'ucon_email_fale_conosco'),
    leituraAberto: _booleano(json, 'uconLeituraAberto', 'ucon_leitura_aberto'),
    quantidadeLogsAcesso: JsonReader.inteiro(json, 'uconQuantidadeLogsAcesso', 'ucon_quantidade_logs_acesso'),
    quantidadeLogsNotificacao: JsonReader.inteiro(
      json,
      'uconQuantidadeLogsNotificacacao',
      'ucon_quantidade_logs_notificacacao',
    ),
    createdAt: JsonReader.data(json, 'createdAt', 'created_at')?.toLocal(),
    updateAt: JsonReader.data(json, 'updateAt', 'update_at')?.toLocal(),
  );

  /// Corpo de POST e PUT (o `usuaId` vem do token; [uconId] só no PUT).
  Map<String, dynamic> toJson() => {
    if (uconId != null) 'uconId': uconId,
    'uconEmailVersiculo': emailVersiculo,
    'uconEmailComunidade': emailComunidade,
    'uconEmailLeitura': emailLeitura,
    'uconLeituraAberto': leituraAberto,
    'uconQuantidadeLogsAcesso': quantidadeLogsAcesso,
    'uconQuantidadeLogsNotificacacao': quantidadeLogsNotificacao,
    'uconEmailFaleConosco': emailFaleConosco,
  };

  UsuarioConfiguracaoModel copyWith({
    int? uconId,
    bool? emailVersiculo,
    bool? emailComunidade,
    bool? emailLeitura,
    bool? emailFaleConosco,
    bool? leituraAberto,
    int? quantidadeLogsAcesso,
    int? quantidadeLogsNotificacao,
  }) => UsuarioConfiguracaoModel(
    uconId: uconId ?? this.uconId,
    emailVersiculo: emailVersiculo ?? this.emailVersiculo,
    emailComunidade: emailComunidade ?? this.emailComunidade,
    emailLeitura: emailLeitura ?? this.emailLeitura,
    emailFaleConosco: emailFaleConosco ?? this.emailFaleConosco,
    leituraAberto: leituraAberto ?? this.leituraAberto,
    quantidadeLogsAcesso: quantidadeLogsAcesso ?? this.quantidadeLogsAcesso,
    quantidadeLogsNotificacao: quantidadeLogsNotificacao ?? this.quantidadeLogsNotificacao,
    createdAt: createdAt,
    updateAt: updateAt,
  );

  /// Mesmos valores (ignora id e datas).
  bool mesmosValores(UsuarioConfiguracaoModel outra) =>
      emailVersiculo == outra.emailVersiculo &&
      emailComunidade == outra.emailComunidade &&
      emailLeitura == outra.emailLeitura &&
      emailFaleConosco == outra.emailFaleConosco &&
      leituraAberto == outra.leituraAberto &&
      quantidadeLogsAcesso == outra.quantidadeLogsAcesso &&
      quantidadeLogsNotificacao == outra.quantidadeLogsNotificacao;

  static bool _booleano(Map<String, dynamic> json, String camel, String snake) => switch (json[camel] ?? json[snake]) {
    final bool valor => valor,
    _ => throw FormatException('campoInvalido', camel),
  };
}
