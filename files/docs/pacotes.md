# Pacotes compartilhados

## commons ([`commons/lib`](../../commons/lib))

| Arquivo | Exporta | Função |
|---|---|---|
| [api_core.dart](../../commons/lib/api/api_core.dart) | `ApiCore`, `HeaderType`, `Header`, `kDesHost`, `kPrdHost` | Enum com cada endpoint (caminho, host de desenvolvimento, host de produção e tipo de header). `Header.getHeader` monta os headers. `minimal` não acrescenta nada. `basicInfo` acrescenta `x-access-interface: App` e `x-access-token` (de `AppSession`; vazio se a configuração não foi lida). `loggedUser` acrescenta `x-token` e `x-user`. `loggedArea` acrescenta também `x-empresa`. Sem sessão, `loggedUser` e `loggedArea` lançam `StateError('headerInvalido')`. |
| [auth_session.dart](../../commons/lib/commons/auth_session.dart) | `AuthSession` | Singleton com token, `userId` e `emprId` do usuário logado. `isLogged` alimenta a proteção de rotas. |
| [app_session.dart](../../commons/lib/commons/app_session.dart) | `AppSession` | Singleton com a configuração de `GET /v1/configuracao-app`: `cryptKey`, `cryptKeyB64` e `accessTokenId`. |
| [result.dart](../../commons/lib/commons/result.dart) | `Result`, `Ok`, `Error` | Retorno de toda operação assíncrona. Use `switch` para tratar os dois casos. |
| [handed_exception.dart](../../commons/lib/commons/handed_exception.dart) | `HandledException` | Erro tratado; `message` é uma chave de tradução. |
| [constants.dart](../../commons/lib/commons/constants.dart) | `kVazio`, `kDefaultAppError`, `kColorScheme`, `kSelectedLanguage`, `kSelectedBibleVersion`, `kApp`, `kApi`, `kConfCryptKey`, `kConfCryptKeyB64`, `kConfAccessTokenId` | Constantes globais. As `kConf*` são as chaves (`citeChave`) devolvidas por `/v1/configuracao-app`. |
| [encrypt.dart](../../commons/lib/commons/encrypt.dart) | `Encrypt` | AES-256-GCM. O payload é base64 de `iv(12) + cifrado + tag(16)`, mesmo formato da `biblia_api`. |
| [secure_storage.dart](../../commons/lib/storage/secure_storage.dart), [secure_storage_model.dart](../../commons/lib/storage/secure_storage_model.dart) | `BBSecureStorage`, `SecureStorageModel` | Leitura e gravação com `flutter_secure_storage`. |
| [log.dart](../../commons/lib/commons/log.dart) | `Log.print`, `Log.printJson` | Log no console. Desligado em release. |

## service ([`service/lib/api`](../../service/lib/api))

| Arquivo | Exporta | Função |
|---|---|---|
| [dio_provider.dart](../../service/lib/api/dio_provider.dart) | `DioProvider` | `DioProvider.of(ApiCore.x).request(verb:, pathParam:, queryParam:, body:, timeout: 30)` devolve `Result<dynamic>`. Usa o host `prd` em release e `des` nas demais builds; no Android, `localhost` vira `10.0.2.2`. POST e PUT exigem corpo e removem os valores nulos. Erros do Dio viram `HttpServiceException`, com o `code` HTTP e a `message` da API (ex.: `registroNaoEncontrado`). |
| [enum.dart](../../service/lib/api/enum.dart) | `Verb` | `get`, `post`, `put`, `delete`. |
| [service_exception.dart](../../service/lib/api/service_exception.dart), [http_service_exception_model.dart](../../service/lib/api/http_service_exception_model.dart) | `HttpServiceException` | Erro de chamada HTTP. |

## components ([`components/lib`](../../components/lib))

| Item | Função |
|---|---|
| [theme/app_theme.dart](../../components/lib/theme/app_theme.dart) | `AppTheme.light` / `AppTheme.dark` (Material 3), montados com `AppColors`. |
| [theme/app_colors.dart](../../components/lib/theme/app_colors.dart) | `AppColors` (marca: `brandNavy`, `brandGold`, `brandParchment`) e `AppPalette` para claro e escuro. |
| [theme/app_typography.dart](../../components/lib/theme/app_typography.dart) | `AppTypography.textTheme` e fontes de leitura. |
| [theme/app_spacing.dart](../../components/lib/theme/app_spacing.dart) | `AppSpacing` (xs 4, sm 8, md 16, lg 24, xl 32) e `AppRadius`. |
| [theme/reading_colors.dart](../../components/lib/theme/reading_colors.dart) | `ReadingColors`: cores da tela de leitura, como `ThemeExtension`. |
| [components/dialog](../../components/lib/components/dialog) | `DialogBottomSheet` e `DialogBottomSheetWarning` (status, tipo e layout dos botões), usados nos erros e nas confirmações. Formulários e detalhes abrem no `DialogBottomSheet` pelo helper `DialogSheet.show` ([app/lib/config/dialog_sheet.dart](../../app/lib/config/dialog_sheet.dart)); não usar `showDialog`/`AlertDialog`. |
| [components/loading](../../components/lib/components/loading) | `Loading` de tela cheia. |
| [components/view_bottom_actions](../../components/lib/components/view_bottom_actions) | Barra de ações no rodapé. |
| [components/button](../../components/lib/components/button) | Widget `Button`, configurado por `ButtonDls` (`ButtonSize`, `ButtonStatus`, `ButtonType`). Não é exportado por `components.dart`; importe o arquivo direto. |

Os cards da dashboard usam `Card` do Material com o tema acima: cabeçalho com ícone em `colorScheme.primary` e título em `labelLarge`, padding `16, 16, 16, 8` e `SizedBox(height: 16)` entre os cards.
