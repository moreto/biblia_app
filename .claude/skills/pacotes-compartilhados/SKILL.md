---
name: pacotes-compartilhados
description: Referência dos pacotes locais commons (ApiCore, headers, sessões, Result, HandledException, Encrypt, secure storage, constantes, Log), service (DioProvider, Verb, HttpServiceException) e components (AppTheme, AppColors, ReadingColors, AppSpacing, DialogBottomSheet, Loading, ViewBottomActions, Button). Use ao adicionar endpoint, escolher header, chamar a API, usar cores/espaçamentos do tema ou reutilizar um componente visual em vez de criar um novo.
---

# Pacotes compartilhados

Fonte completa: `files/docs/pacotes.md`. Antes de criar um utilitário ou widget, verifique se ele já existe aqui.

## commons (`commons/lib`)

- **Endpoint novo:** acrescente ao enum `ApiCore` (`commons/lib/api/api_core.dart`) com o `HeaderType` certo:
  - `minimal`: nenhum header extra
  - `basicInfo`: `x-access-interface` + `x-access-token` (de `AppSession`)
  - `loggedUser`: + `x-token` e `x-user`
  - `loggedArea`: + `x-empresa` (padrão para telas logadas)
  - Sem sessão, `loggedUser`/`loggedArea` lançam `StateError('headerInvalido')`.
- `Result` / `Ok` / `Error` para toda operação assíncrona.
- `HandledException.message` é chave de tradução.
- `Encrypt`: AES-256-GCM, payload base64 de `iv(12) + cifrado + tag(16)`.
- Persistência: `BBSecureStorage` + `SecureStorageModel`; chaves em `constants.dart`.
- `Log.print` / `Log.printJson` (desligado em release).

## service (`service/lib/api`)

- `DioProvider.of(ApiCore.x).request(verb:, pathParam:, queryParam:, body:, timeout: 30)` → `Result<dynamic>`.
- POST/PUT exigem corpo e removem nulos. Erros viram `HttpServiceException` com `code` HTTP e `message` da API.
- Host `prd` em release, `des` nas outras builds; no Android `localhost` vira `10.0.2.2`.

## components (`components/lib`)

- Cores: nunca usar `Color(0x...)` fora de `theme/app_colors.dart`. Use `Theme.of(context).colorScheme` ou `ReadingColors.of(context)` (tela de leitura).
- Espaçamentos e raios: `AppSpacing` (xs 4, sm 8, md 16, lg 24, xl 32) e `AppRadius`.
- Diálogos: `DialogBottomSheet` / `DialogBottomSheetWarning`; abrir com `DialogSheet.show` (`app/lib/config/dialog_sheet.dart`).
- `Loading`, `ViewBottomActions`, `Button` (este não é exportado por `components.dart`; importe o arquivo direto).
- Cards da dashboard: `Card` do Material, ícone em `colorScheme.primary`, título `labelLarge`, padding `16, 16, 16, 8`, `SizedBox(height: 16)` entre cards.

Se mudar a API pública de um desses pacotes, atualize `files/docs/pacotes.md`.
