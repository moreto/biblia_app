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

/// Prefixo das marcações do marca-texto da leitura, uma chave por capítulo (`prefixo:versaId:livrId:capiNumero`).
const String kReadingHighlights = 'readingHighlights';

/// Tema só da leitura: `sistema` (o mesmo do app), `claro`, `creme` ou `escuro`.
const String kReadingTheme = 'readingTheme';
const String kReadingBrightness = 'readingBrightness';
const String kReadingHighlightColor = 'readingHighlightColor';

/// Orientação da tela na leitura: `automatica`, `retrato` ou `paisagem`.
const String kReadingOrientation = 'readingOrientation';

/// Prefixo das anotações da leitura, uma chave por capítulo (`prefixo:versaId:livrId:capiNumero`).
const String kReadingNotes = 'readingNotes';

/// Tags das anotações da leitura (lista em JSON).
const String kReadingTags = 'readingTags';

// log values
const String kApp = 'Bbl App';
const String kApi = 'Bbl Api';

// chaves (`citeChave`) devolvidas por GET /v1/configuracao-app
const String kConfCryptKey = 'kCryptKey';
const String kConfCryptKeyB64 = 'kCryptKeyB64';
const String kConfAccessTokenId = 'kAccessTokenId';
