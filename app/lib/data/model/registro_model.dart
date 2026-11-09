/// Resposta de `POST /v1/acesso/registro`: o usuário criado (inativo até confirmar o código de ativação).
class RegistroModel {
  const RegistroModel({required this.usuaId, required this.usuaEmail, this.usuaUuid});

  final int usuaId;
  final String usuaEmail;
  final String? usuaUuid;

  factory RegistroModel.fromJson(Map<String, dynamic> json) => RegistroModel(
    usuaId: ((json['usuaId'] ?? json['usua_id']) as num).toInt(),
    usuaEmail: (json['usuaEmail'] ?? json['usua_email']) as String,
    usuaUuid: (json['usuaUuid'] ?? json['usua_uuid']) as String?,
  );

  Map<String, dynamic> toJson() => {'usuaId': usuaId, 'usuaEmail': usuaEmail, 'usuaUuid': usuaUuid};
}
