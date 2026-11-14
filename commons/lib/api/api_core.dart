import 'package:commons/commons.dart';

enum HeaderType { minimal, basicInfo, loggedUser, loggedArea }

// internet roteada do celular
// const String kDesHost = 'http://10.0.2.2:3000/api';
// const String kPrdHost = 'http://172.20.10.14:3000/api';

// acesso externo
// const String kDesHost = 'http://179.252.135.186:3000/api';
// const String kPrdHost = 'http://179.252.135.186:3000/api';

// interno / localhost
// const String kDesHost = 'http://192.168.1.45:3000/api';
// const String kPrdHost = 'http://192.168.1.45:3000/api';

// const String kDesHost = 'http://127.20.10.2:3000/api';
// const String kDesHost = 'http://localhost:3000/api';
const String kDesHost = 'http://192.168.1.45:3000/api';
// prod ou externo para desenvolvimento
// const String kDesHost = 'http://179.252.135.186:3000/api';
const String kPrdHost = 'http://179.252.135.186:3000/api';

enum ApiCore {
  // Pública (fora da área logada)
  configuracaoApp('/v1/configuracao-app', kDesHost, kPrdHost, HeaderType.minimal),
  funcionalidade('/v1/funcionalidade', kDesHost, kPrdHost, HeaderType.minimal),
  healt('', kDesHost, kPrdHost, HeaderType.minimal),

  // Pública (fora da área logada): a API valida só o x-access-token.
  login('/v1/acesso/login', kDesHost, kPrdHost, HeaderType.basicInfo),
  otpSend('/v1/otp/send', kDesHost, kPrdHost, HeaderType.basicInfo),
  otpVerify('/v1/otp/verify', kDesHost, kPrdHost, HeaderType.basicInfo),
  registro('/v1/acesso/registro', kDesHost, kPrdHost, HeaderType.basicInfo),
  traducao('/v1/traducao', kDesHost, kPrdHost, HeaderType.basicInfo),
  usuarioAtivacaoConfirmar('/v1/usuario-ativacao/confirmar', kDesHost, kPrdHost, HeaderType.basicInfo),

  // Area Logada (requere autenticação)
  bibliaCapitulo('/v1/biblia/capitulo', kDesHost, kPrdHost, HeaderType.loggedArea),
  bibliaIndice('/v1/biblia/indice', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidade('/v1/comunidade', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeContato('/v1/comunidade-contato', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeDenominacao('/v1/comunidade-denominacao', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeHumanogramaDto('/v1/comunidade-humanograma-dto', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeEndereco('/v1/comunidade-endereco', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeTipo('/v1/comunidade-tipo', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeUsuario('/v1/comunidade/usuario', kDesHost, kPrdHost, HeaderType.loggedArea),
  comunidadeUsuarioVinculo('/v1/comunidade-usuario', kDesHost, kPrdHost, HeaderType.loggedArea),
  estado('/v1/estado', kDesHost, kPrdHost, HeaderType.loggedArea),
  municipio('/v1/municipio', kDesHost, kPrdHost, HeaderType.loggedArea),
  configuracao('/v1/configuracao', kDesHost, kPrdHost, HeaderType.loggedArea),
  configuracaoItem('/v1/configuracao-item', kDesHost, kPrdHost, HeaderType.loggedArea),
  dicionarioBusca('/v1/dicionario/busca', kDesHost, kPrdHost, HeaderType.loggedArea),
  dicionarioPalavra('/v1/dicionario/palavra', kDesHost, kPrdHost, HeaderType.loggedArea),
  livro('/v1/livro', kDesHost, kPrdHost, HeaderType.loggedArea),
  log('/v1/log', kDesHost, kPrdHost, HeaderType.loggedArea),
  menu('/v1/menu', kDesHost, kPrdHost, HeaderType.loggedArea),
  mensagem('/v1/mensagem', kDesHost, kPrdHost, HeaderType.loggedArea),
  mensagemRecebidas('/v1/mensagem-usuario/recebidas', kDesHost, kPrdHost, HeaderType.loggedArea),
  mensagemNaoLidas('/v1/mensagem-usuario/nao-lidas', kDesHost, kPrdHost, HeaderType.loggedArea),
  mensagemUsuario('/v1/mensagem-usuario', kDesHost, kPrdHost, HeaderType.loggedArea),
  mensagemTipo('/v1/mensagem-tipo', kDesHost, kPrdHost, HeaderType.loggedArea),
  musicaAleatoria('/v1/musica/aleatoria', kDesHost, kPrdHost, HeaderType.loggedArea),
  notificacao('/v1/notificacao', kDesHost, kPrdHost, HeaderType.loggedArea),
  oracaoAleatoria('/v1/oracao/aleatoria', kDesHost, kPrdHost, HeaderType.loggedArea),
  renomado('/v1/renomado', kDesHost, kPrdHost, HeaderType.loggedArea),
  testamento('/v1/testamento', kDesHost, kPrdHost, HeaderType.loggedArea),
  usuarioBusca('/v1/usuario/busca', kDesHost, kPrdHost, HeaderType.loggedArea),
  usuarioDispositivo('/v1/usuario-dispositivo', kDesHost, kPrdHost, HeaderType.loggedUser),
  versao('/v1/versao', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoAleatorio('/v1/versiculo/aleatorio', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoIndicacao('/v1/versiculo-indicacao', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoIndicacaoCapitulo('/v1/versiculo-indicacao/capitulo', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoIndicacaoUsuario('/v1/versiculo-indicacao-usuario', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoIndicacaoRecebidas('/v1/versiculo-indicacao-usuario/recebidas', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoRenomado('/v1/versiculo-renomado', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoReacao('/v1/versiculo-reacao', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoReacaoCapitulo('/v1/versiculo-reacao/capitulo', kDesHost, kPrdHost, HeaderType.loggedArea),
  versiculoReacaoLidos('/v1/versiculo-reacao/lidos', kDesHost, kPrdHost, HeaderType.loggedArea);

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
    return {...header, 'x-access-interface': 'App', 'x-access-token': AppSession.instance.accessTokenId ?? kVazio};
  }
}
