// commmon values
const String kVazio = '';
const String kDefaultAppError = 'defaultAppError';

// App
const String kColorScheme = 'colorScheme';
const String kSelectedLanguage = 'selectedLanguage';
const String kSelectedBibleVersion = 'selectedBibleVersion';

/// Último capítulo aberto na leitura, gravado como `versaId:livrId:capiNumero`.
const String kLastReadChapter = 'lastReadChapter';

/// Multiplicador do tamanho da fonte dos versículos na leitura (ex.: `1.2`).
const String kReadingFontScale = 'readingFontScale';

/// Mostrar as setas anterior/próximo na navegação da leitura (`true`/`false`).
const String kReadingShowArrows = 'readingShowArrows';

/// O que fazer com o capítulo ao passar para o próximo: `nunca`, `perguntar` ou `sempre` (marcar como lido).
const String kReadingMarkOnTurn = 'readingMarkOnTurn';

/// Nome da voz escolhida para a narração da leitura.
const String kReadingVoice = 'readingVoice';

/// Velocidade da narração da leitura (0,5 = normal).
const String kReadingSpeechRate = 'readingSpeechRate';

/// Narração contínua: ao terminar o capítulo, passa a página e continua lendo (`true`/`false`).
const String kReadingAutoTurn = 'readingAutoTurn';

// log values
const String kApp = 'Bbl App';
const String kApi = 'Bbl Api';

// chaves (`citeChave`) devolvidas por GET /v1/configuracao-app
const String kConfCryptKey = 'kCryptKey';
const String kConfCryptKeyB64 = 'kCryptKeyB64';
const String kConfAccessTokenId = 'kAccessTokenId';
