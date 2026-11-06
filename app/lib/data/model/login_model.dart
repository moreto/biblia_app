// Resposta de POST /v1/acesso/login e POST /v1/otp/verify: { usuaId, token }.

class LoginModel {
  final int usuaId;
  final String token;

  LoginModel({required this.usuaId, required this.token});

  factory LoginModel.fromJson(Map<String, dynamic> json) =>
      LoginModel(usuaId: (json['usuaId'] as num).toInt(), token: json['token'] as String);

  Map<String, dynamic> toJson() => {'usuaId': usuaId, 'token': token};
}
