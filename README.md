# biblia_app

App Flutter do projeto Bíblia: leitura da Bíblia com marcação de capítulos e versículos lidos, dashboard com cards de oração, versículo e música, e telas administrativas (menu, configuração, log e notificação). Consome a API [`biblia_api`](../biblia_api) e traz textos e menus do banco: as traduções vêm de `/v1/traducao` e os menus de `/v1/menu`.

## Estrutura

O repositório tem quatro pacotes Dart, ligados por `path` no `pubspec.yaml`:

| Pacote | Conteúdo |
|---|---|
| [`app/`](app) | O aplicativo: features, rotas, injeção de dependências, traduções e ícones |
| [`commons/`](commons) | Endpoints (`ApiCore`), headers, `Result`, sessões (`AuthSession`, `AppSession`), secure storage, criptografia, log e constantes |
| [`service/`](service) | Cliente HTTP (`DioProvider`) e exceções de serviço |
| [`components/`](components) | Tema (cores, tipografia, espaçamento) e componentes visuais compartilhados |

Outras pastas:

- [`files/database/`](files/database): scripts SQL das traduções de cada feature.
- [`files/prompts/`](files/prompts): `l10n.csv` (exportação da tabela `traducao`) e prompts de desenvolvimento.
- [`files/docs/`](files/docs): documentação do código.
- [`utils/scripts/`](utils/scripts): scripts de manutenção.

## Como rodar

1. Suba a `biblia_api` e ajuste `kDesHost` / `kPrdHost` em [`commons/lib/api/api_core.dart`](commons/lib/api/api_core.dart) para o endereço dela. Com `localhost`, o emulador Android usa `10.0.2.2` automaticamente; em aparelho físico, use o IP da máquina.
2. Instale as dependências de todos os pacotes: `./utils/scripts/pub_get.sh`. Com `--clean`, roda `flutter clean` antes.
3. Rode o app a partir de `app/`: `flutter run`.

Em `app/`, `./update.sh` refaz tudo do zero. Ele apaga os `pubspec.lock` e o `Podfile.lock`, roda clean e pub get em todos os pacotes, instala o mason (`mason get`) e mostra o `dart fix --dry-run`.

## Validação

Rode em `app/`, `commons/` e `components/`:

```bash
dart format -l 120 lib test
flutter analyze
flutter test
```

## Documentação

Veja [files/docs/README.md](files/docs/README.md).
