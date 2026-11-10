# Arquitetura

## Camadas (MVVM)

Cada feature fica em `app/lib/features/<dominio>/<feature>/` e tem quatro camadas:

```
View → Viewmodel → UseCase → Repository → DioProvider → biblia_api
```

| Camada | Arquivo | Responsabilidade |
|---|---|---|
| **View** | `ui/<feature>_view.dart` | Só layout. Ouve o viewmodel com `ListenableBuilder`, traduz as chaves com `AppLocalizations.of(context).translate(...)` e mostra erros (SnackBar ou `DialogBottomSheetWarning`). |
| **Viewmodel** | `ui/<feature>_viewmodel.dart` | `ChangeNotifier` que guarda o estado da tela e expõe `Command`s. Chama o use case e notifica; não tem regra de negócio. |
| **Use case** | `use_case/<feature>_usecase.dart` | Regras de negócio: validações, regex, criptografia, gravação de sessão, filtros e conversão de erros da API em chaves de tradução (`HandledException(message: 'chave')`). |
| **Repository** | `repository/<feature>_repository.dart` (contrato) e `_repository_impl.dart` | Chama o endpoint com `DioProvider.of(ApiCore.x).request(...)` e converte o JSON no model. Resposta em formato inesperado vira `respostaApiInvalida` ou `formato<X>Invalido`. |

Os models ficam em [`app/lib/data/model/`](../../app/lib/data/model), com `fromJson` e `toJson` escritos à mão. O `fromJson` aceita as chaves em camelCase (`oracNome`) e em snake_case (`orac_nome`).

## Fluxo de uma ação

1. A view chama `viewModel.xCommand.execute(...)`.
2. O [`Command`](../../app/lib/config/command.dart) (`Command0`, sem argumento, ou `Command1<T, A>`, com um argumento) marca `running`, impede execução dupla e chama a função do viewmodel.
3. O viewmodel chama o use case, atualiza o estado e chama `notifyListeners()`.
4. O use case aplica as regras e chama o repository.
5. O repository devolve um `Result<T>`: `Ok(value)` ou `Error(exception)`.
6. A view ouve o command (`addListener` no `initState`), mostra o erro traduzido e chama `clearResult()`.

A mensagem de erro sai da exceção. `HandledException.message` e `HttpServiceException.message` são chaves de tradução; sem mensagem, usa-se `kDefaultAppError`.

## Injeção de dependências e rotas

- [`config/dependencies.dart`](../../app/lib/config/dependencies.dart): registra o `AppConfig` e os repositories no `GetIt` (`locator`) como `registerLazySingleton<XRepository>(() => XRepositoryImpl())`.
- [`routing/router/*_router.dart`](../../app/lib/routing/router): cada grupo de rotas cria o viewmodel e o use case no `builder` do `GoRoute`, pegando o repository do `locator`. As constantes de caminho ficam em [`routing/routes.dart`](../../app/lib/routing/routes.dart) e o `GoRouter` é montado em [`routing/router.dart`](../../app/lib/routing/router.dart).
- [`config/providers.dart`](../../app/lib/config/providers.dart): registra só o `AppConfig` (tema e idioma) como `ChangeNotifierProvider`.

## Estado global

| Classe | Onde | Conteúdo |
|---|---|---|
| `AppSession` | `commons` | Configuração de `GET /v1/configuracao-app`: `cryptKeyB64` (chave AES da senha) e `accessTokenId` (header `x-access-token`). Lida no `main` pelo `ConfiguracaoAppUseCase`, não depende do usuário e não é limpa no logoff. |
| `AuthSession` | `commons` | Token e `usuaId` do login, usados nos headers `loggedUser` e `loggedArea`. É gravada pelo `LoginUseCase` e limpa no logoff. |
| `UsuarioSession` | [`config/usuario_session.dart`](../../app/lib/config/usuario_session.dart) | Detalhe do usuário logado. |
| `AppConfig` | [`config/app_config.dart`](../../app/lib/config/app_config.dart) | Tema (`ThemeMode`), idioma e versão da Bíblia, persistidos no secure storage (`kColorScheme`, `kSelectedLanguage`, `kSelectedBibleVersion`). `ThemeModeButton` e `OrientationButton` alteram tema e idioma; a versão é exposta aos use cases pela interface [`VersaoPreferencia`](../../app/lib/config/versao_preferencia.dart). |

## Proteção de rotas

O `redirect` do `GoRouter` chama `authRedirect` ([`routing/auth_guard.dart`](../../app/lib/routing/auth_guard.dart)):

- Sem login, só `/home`, `/login` e `/registro` abrem; as demais rotas (e `/`, que não tem tela) vão para `/home`.
- Com login, `/`, `/home` e `/login` vão para `/dashboard`.

## Traduções

[`l10n/app_localizations.dart`](../../app/lib/l10n/app_localizations.dart) carrega todas as traduções de `GET /v1/traducao` quando o app abre. Idiomas suportados: `pt-BR`, `es-ES` e `en-US`.

- `translate(chave)` procura pela `trad_chave` ou pelo texto em pt-BR, sem diferenciar maiúsculas, acentos ou espaços.
- Chave sem tradução aparece na tela como a própria chave. Isso facilita encontrar o que falta.
- Toda tradução nova precisa de script SQL. Veja [desenvolvimento.md](./desenvolvimento.md#traduções).

## Menu e ícones

A dashboard monta a `NavigationBar` com os menus de `GET /v1/menu`. Menus com filhos abrem um bottom sheet com `QuickCard`s. O ícone vem de `menu_icone`, uma chave do Material Design Icons (ex.: `book-open-variant`), resolvida em [`config/icons_map.dart`](../../app/lib/config/icons_map.dart). Os cards também usam o `IconsMap`, com um ícone do Material como reserva caso a chave não esteja mapeada.

## Convenções

- Regras de negócio só no use case; a view nunca valida.
- Mensagens para o usuário são sempre chaves de tradução, nunca textos fixos.
- Cada card da dashboard tem viewmodel próprio, criado no `CommonRouter` e passado à `DashboardView`.
- Comentários e nomes em português, como no restante do projeto.
- Formatação: `dart format -l 120`. Lints: `flutter_lints`.

## Pontos de atenção conhecidos

- **Configuração na abertura:** a chave de criptografia e o access token vêm de `GET /v1/configuracao-app` (sem headers de acesso). Se a chamada falhar no `main`, as rotas `basicInfo` (traduções, login, registro) saem com `x-access-token` vazio; login e registro tentam ler a configuração de novo antes de criptografar a senha.
- **Hosts:** `kDesHost` é `localhost` (no emulador Android o `DioProvider` troca por `10.0.2.2`) e `kPrdHost` é um IP externo. O `DioProvider` usa `prd` em release e `des` nas demais builds.
- **HTTP sem TLS:** a API responde em `http`. O Android (a partir do 9) e o iOS (ATS) bloqueiam `http` em release sem configuração extra (`usesCleartextTraffic` / `NSAppTransportSecurity`), que hoje não existe no projeto. O ideal é servir a API em `https`.
