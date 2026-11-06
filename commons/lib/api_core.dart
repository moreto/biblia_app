import 'package:commons/commons.dart';

enum HeaderType { minimal, basicInfo, loggedUser, loggedArea }

// const String kDesHost = 'http://192.168.1.70:3000/api';
// const String kPrdHost = 'http://192.168.1.70:3000/api';

// const String kDesHost = 'http://10.0.2.2:3000/api';
// const String kPrdHost = 'http://172.20.10.14:3000/api';

// const String kDesHost = 'https://texho.vercel.app/api';
// const String kPrdHost = 'https://texho.vercel.app/api';

// const String kDesHost = 'http://179.252.135.186:3000/api';
// const String kPrdHost = 'http://179.252.135.186:3000/api';

const String kDesHost = 'http://192.168.1.45:3000/api';
const String kPrdHost = 'http://192.168.1.45:3000/api';

enum ApiCore {
  traducao('/v1/traducao', kDesHost, kPrdHost, HeaderType.minimal),
  healt('', kDesHost, kPrdHost, HeaderType.minimal),
  register('/v1/acesso/registro', kDesHost, kPrdHost, HeaderType.minimal),
  login('/v1/acesso/login', kDesHost, kPrdHost, HeaderType.basicInfo),
  menu('/v1/menu', kDesHost, kPrdHost, HeaderType.loggedArea),
  log('/v1/log', kDesHost, kPrdHost, HeaderType.loggedArea),
  notificacao('/v1/notificacao', kDesHost, kPrdHost, HeaderType.loggedArea),
  requestOtp('/v1/otp/send', kDesHost, kPrdHost, HeaderType.basicInfo),
  verifyOtp('/v1/otp/verify', kDesHost, kPrdHost, HeaderType.basicInfo),
  empresa('/v1/empresa', kDesHost, kPrdHost, HeaderType.loggedArea),
  empresaUsuarioVincular('/v1/empresa/usuario/vincular', kDesHost, kPrdHost, HeaderType.loggedUser),
  empresaUsuarioDetalhe('/v1/empresa/usuario/detalhe', kDesHost, kPrdHost, HeaderType.loggedArea),
  usuarioDetalheById('/v1/usuario/usuario-detalhe-by-id', kDesHost, kPrdHost, HeaderType.loggedArea),
  usuarioDispositivo('/v1/usuario-dispositivo', kDesHost, kPrdHost, HeaderType.loggedArea);

  const ApiCore(this.endpoint, this.des, this.prd, this.headerType);
  final String endpoint;
  final String des;
  final String prd;
  final HeaderType headerType;
}

class Header {
  static final Map<String, String> header = {
    'Access-Control-Allow-Origin': 'true',
    'Access-Control-Allow-Methods': '*',
    'Access-Control-Allow-Headers': '*',
    'Content-Type': 'application/json; charset=UTF-8',
    'Charset': 'utf-8',
  };

  static Map<String, String> getHeader(HeaderType headerType) {
    switch (headerType) {
      case HeaderType.minimal:
        return header;
      case HeaderType.basicInfo:
        return buildHeaders();
      case HeaderType.loggedUser:
        return buildHeadersLoggedUserOnly();
      case HeaderType.loggedArea:
        return buildHeadersLoggedUser();
    }
  }

  static Map<String, String> buildHeadersLoggedUser() {
    final session = AuthSession.instance;
    final token = session.token;
    final userId = session.userId;
    final emprId = session.emprId;
    if (token == null || userId == null) {
      throw StateError('headerInvalido');
    }

    return {...buildHeaders(), 'x-token': token, 'x-user': userId.toString(), 'x-empresa': emprId.toString()};
  }

  static Map<String, String> buildHeadersLoggedUserOnly() {
    final session = AuthSession.instance;
    final token = session.token;
    final userId = session.userId;
    if (token == null || userId == null) {
      throw StateError('headerInvalido');
    }

    return {...buildHeaders(), 'x-token': token, 'x-user': userId.toString()};
  }

  static Map<String, String> buildHeaders() {
    return {...header, 'x-access-interface': 'App', 'x-access-token': kAccessTokenId};
  }
}
