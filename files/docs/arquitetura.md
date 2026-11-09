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

- [`config/dependencies.dart`](../../app/lib/config/dependencies.dart): registra os repositories no `GetIt` (`locator`) como `registerLazySingleton<XRepository>(() => XRepositoryImpl())`.
- [`routing/router/*_router.dart`](../../app/lib/routing/router): cada grupo de rotas cria o viewmodel e o use case no `builder` do `GoRoute`, pegando o repository do `locator`. As constantes de caminho ficam em [`routing/routes.dart`](../../app/lib/routing/routes.dart) e o `GoRouter` é montado em [`routing/router.dart`](../../app/lib/routing/router.dart).
- [`config/providers.dart`](../../app/lib/config/providers.dart): registra só o `AppConfig` (tema e idioma) como `ChangeNotifierProvider`.

## Estado global

| Classe | Onde | Conteúdo |
|---|---|---|
| `AuthSession` | `commons` | Token e `usuaId` do login, usados nos headers `loggedArea`. É gravada pelo `LoginUseCase` e limpa no logoff. |
| `UsuarioSession` | [`config/usuario_session.dart`](../../app/lib/config/usuario_session.dart) | Detalhe do usuário logado. |
| `AppConfig` | [`config/app_config.dart`](../../app/lib/config/app_config.dart) | Tema (`ThemeMode`) e idioma, persistidos no secure storage (`kColorScheme`, `kSelectedLanguage`). `ThemeModeButton` e `OrientationButton` alteram essas preferências. |

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

- **Segredos no código:** `kCryptKeyB64` e `kAccessTokenId` ficam em [`commons/lib/commons/constants.dart`](../../commons/lib/commons/constants.dart) e vão para o binário.
- **Hosts:** `kDesHost` e `kPrdHost` apontam hoje para o mesmo IP local. O `DioProvider` usa `prd` em release e `des` nas demais builds.
- **Rotas sem proteção:** o `redirect` do `GoRouter` só registra a rota em log. Nada impede abrir `/dashboard` sem login. Nesse caso, as chamadas `loggedArea` falham com `headerInvalido`.
- **Traduções antigas:** algumas telas antigas (logoff, `Sair` na dashboard) passam o texto em pt-BR no lugar da chave. Funciona porque o `translate` também procura pelo texto em pt-BR.
