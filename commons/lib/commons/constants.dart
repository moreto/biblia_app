// commmon values
const String kVazio = '';
const String kDefaultAppError = 'defaultAppError';

// App
const String kColorScheme = 'colorScheme';
const String kSelectedLanguage = 'selectedLanguage';
const String kSelectedBibleVersion = 'selectedBibleVersion';

// log values
const String kApp = 'Bbl App';
const String kApi = 'Bbl Api';

// config
/// Access token inicial: `GET /v1/configuracao-app` também exige `x-access-token`, então o app precisa de um
/// valor embutido para a primeira chamada. Depois dela vale o que a API devolver ([AppSession.accessTokenId]).
// const String kAccessTokenId = '56ce516cb9f3a0095e069b0610db7017';

// chaves (`citeChave`) devolvidas por GET /v1/configuracao-app
const String kConfCryptKey = 'kCryptKey';
const String kConfCryptKeyB64 = 'kCryptKeyB64';
const String kConfAccessTokenId = 'kAccessTokenId';
