import '../biblia/json_reader.dart';

/// Contatos de uma comunidade (`biblia.comunidade_contato`), como devolvidos por `/v1/comunidade-contato/:comuId`.
///
/// Todos os campos de contato são opcionais e textuais; cada um é identificado pela chave JSON (ex.:
/// `cconWhatsapp`), usada por [campo] e [ComunidadeContatoModel.comCampos].
class ComunidadeContatoModel {
  const ComunidadeContatoModel({
    this.cconId,
    required this.comuId,
    this.cconTelefonePrincipal,
    this.cconTelefoneSecundario,
    this.cconCelular,
    this.cconWhatsapp,
    this.cconEmail,
    this.cconSite,
    this.cconFacebook,
    this.cconInstagram,
    this.cconYoutube,
    this.cconTelegram,
    this.cconDiscord,
  });

  /// Nulo enquanto o contato não foi gravado.
  final int? cconId;
  final int comuId;
  final String? cconTelefonePrincipal;
  final String? cconTelefoneSecundario;
  final String? cconCelular;
  final String? cconWhatsapp;
  final String? cconEmail;
  final String? cconSite;
  final String? cconFacebook;
  final String? cconInstagram;
  final String? cconYoutube;
  final String? cconTelegram;
  final String? cconDiscord;

  /// Chaves JSON dos campos de contato, na ordem da tabela.
  static const chaves = [
    'cconTelefonePrincipal',
    'cconTelefoneSecundario',
    'cconCelular',
    'cconWhatsapp',
    'cconEmail',
    'cconSite',
    'cconFacebook',
    'cconInstagram',
    'cconYoutube',
    'cconTelegram',
    'cconDiscord',
  ];

  factory ComunidadeContatoModel.fromJson(Map<String, dynamic> json) {
    String? texto(String camel) => JsonReader.textoOpcional(json, camel, _snake(camel));
    return ComunidadeContatoModel(
      cconId: JsonReader.inteiroOpcional(json, 'cconId', 'ccon_id'),
      comuId: JsonReader.inteiro(json, 'comuId', 'comu_id'),
      cconTelefonePrincipal: texto('cconTelefonePrincipal'),
      cconTelefoneSecundario: texto('cconTelefoneSecundario'),
      cconCelular: texto('cconCelular'),
      cconWhatsapp: texto('cconWhatsapp'),
      cconEmail: texto('cconEmail'),
      cconSite: texto('cconSite'),
      cconFacebook: texto('cconFacebook'),
      cconInstagram: texto('cconInstagram'),
      cconYoutube: texto('cconYoutube'),
      cconTelegram: texto('cconTelegram'),
      cconDiscord: texto('cconDiscord'),
    );
  }

  /// Contato com os [campos] (chave JSON → valor); chaves ausentes ficam nulas.
  factory ComunidadeContatoModel.comCampos({int? cconId, required int comuId, required Map<String, String?> campos}) =>
      ComunidadeContatoModel.fromJson({...campos, 'cconId': cconId, 'comuId': comuId});

  /// Valor do campo de contato pela chave JSON (ex.: `cconEmail`).
  String? campo(String chave) => toJson()[chave] as String?;

  /// Corpo do POST/PUT (campos nulos são removidos pelo DioProvider).
  Map<String, dynamic> toJson() => {
    'cconId': cconId,
    'comuId': comuId,
    'cconTelefonePrincipal': cconTelefonePrincipal,
    'cconTelefoneSecundario': cconTelefoneSecundario,
    'cconCelular': cconCelular,
    'cconWhatsapp': cconWhatsapp,
    'cconEmail': cconEmail,
    'cconSite': cconSite,
    'cconFacebook': cconFacebook,
    'cconInstagram': cconInstagram,
    'cconYoutube': cconYoutube,
    'cconTelegram': cconTelegram,
    'cconDiscord': cconDiscord,
  };

  static String _snake(String camel) => camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}
