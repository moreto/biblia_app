---
name: arquitetura-mvvm
description: Regras de arquitetura do app Flutter da Bíblia (MVVM com View → Viewmodel → UseCase → Repository → DioProvider), fluxo de Command e Result, injeção com GetIt, rotas GoRouter, sessões, traduções e convenções. Use ao escrever ou revisar qualquer código em app/lib, decidir em qual camada colocar uma regra, tratar erros, criar rotas ou registrar dependências.
---

# Arquitetura

Fonte completa: `files/docs/arquitetura.md`.

## Camadas (por feature em `app/lib/features/<dominio>/<feature>/`)

| Camada | Arquivo | Pode | Não pode |
|---|---|---|---|
| View | `ui/<feature>_view.dart` | Layout, `ListenableBuilder`, `translate(...)`, mostrar erro (SnackBar / `DialogBottomSheetWarning`) | Validar ou ter regra de negócio |
| Viewmodel | `ui/<feature>_viewmodel.dart` | `ChangeNotifier`, estado, `Command`s, chamar use case | Regra de negócio |
| Use case | `use_case/<feature>_usecase.dart` | Validações, regex, criptografia, sessão, filtros, converter erro da API em `HandledException(message: 'chave')` | Chamar Dio diretamente |
| Repository | `repository/<feature>_repository.dart` + `_repository_impl.dart` | `DioProvider.of(ApiCore.x).request(...)`, JSON → model; formato inesperado vira `respostaApiInvalida` / `formato<X>Invalido` | Regra de negócio |

Models em `app/lib/data/model/`, com `fromJson`/`toJson` à mão; `fromJson` aceita camelCase e snake_case.

## Fluxo de uma ação

1. View chama `viewModel.xCommand.execute(...)` (`Command0` ou `Command1<T, A>`, em `app/lib/config/command.dart`).
2. Command marca `running` e impede execução dupla.
3. Viewmodel chama use case, atualiza estado, `notifyListeners()`.
4. Repository devolve `Result<T>` (`Ok` / `Error`), tratado com `switch`.
5. View ouve o command no `initState`, mostra o erro traduzido e chama `clearResult()`.

Mensagem de erro = `exception.message` (chave de tradução); sem mensagem, `kDefaultAppError`.

## Injeção e rotas

- Repositories: `registerLazySingleton<XRepository>(() => XRepositoryImpl())` em `app/lib/config/dependencies.dart`.
- Viewmodel e use case são criados no `builder` do `GoRoute` em `app/lib/routing/router/*_router.dart`; caminhos em `routing/routes.dart`.
- Proteção: `authRedirect` em `routing/auth_guard.dart` (sem login só `/home`, `/home-old`, `/login`, `/registro` e `/biblia-leitura`).

## Convenções obrigatórias

- Textos ao usuário são sempre chaves de tradução, nunca texto fixo. Chave sem tradução aparece como a própria chave.
- Cada card da dashboard tem viewmodel próprio, criado no `CommonRouter`.
- Formulários e detalhes abrem com `DialogSheet.show`; não usar `showDialog`/`AlertDialog`.
- Comentários e nomes em português.
- `dart format -l 120`; lints `flutter_lints`.

Antes de mexer em sessões (`AppSession`, `AuthSession`, `UsuarioSession`, `AppConfig`), hosts ou HTTP, leia "Estado global" e "Pontos de atenção" no doc.
