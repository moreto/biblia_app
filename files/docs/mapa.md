# Mapa do código

Para cada tela: rota, feature, use case e endpoints. Os caminhos de feature são relativos a `app/lib/features/`. Os endpoints estão em `ApiCore` ([`commons/lib/commons/api_core.dart`](../../commons/lib/commons/api_core.dart)), com o prefixo `/api`. A `biblia_api` documenta cada endpoint em `files/docs/mapa.md`.

## Acesso (`AccessRouter`)

| Rota | Feature | Use case | Endpoints | Comportamento |
|---|---|---|---|---|
| `/home` (inicial) | [access/home](../../app/lib/features/access/home) | `HomeUseCase.healt` | `ApiCore.healt` (`/api`) | Verifica se a API responde. Tem atalhos de tema e idioma e leva ao login. |
| — (card) | [access/home/widgets/funcionalidade](../../app/lib/features/access/home/widgets/funcionalidade) | `FuncionalidadeUseCase.listar` | `/v1/funcionalidade` (público) | Lista as funcionalidades do app na ordem da API. As inativas aparecem esmaecidas, com o selo "Em breve". |
| `/login` | [access/login](../../app/lib/features/access/login) | `LoginUseCase.login`, `otpSend`, `otpVerify` | `/v1/acesso/login`, `/v1/otp/send`, `/v1/otp/verify` | Valida e-mail e código de 6 dígitos, criptografa a senha (AES-GCM, `kCryptKeyB64`) e grava `AuthSession`. Depois vai para `/dashboard`. |

## Comum (`CommonRouter`)

| Rota | Feature | Use case | Endpoints | Comportamento |
|---|---|---|---|---|
| `/dashboard` | [dashboard](../../app/lib/features/dashboard) | `DashboardUseCase.menu` | `/v1/menu` | `NavigationBar` com os menus do banco e, no corpo, os cards abaixo, nesta ordem. |
| — (card) | [dashboard/widgets/oracao](../../app/lib/features/dashboard/widgets/oracao) | `OracaoUseCase.aleatoria` | `/v1/oracao/aleatoria` | Oração sorteada, com "Ler mais" e "Outra oração". |
| — (card) | [dashboard/widgets/versiculo](../../app/lib/features/dashboard/widgets/versiculo) + [versiculo_reacao](../../app/lib/features/dashboard/widgets/versiculo_reacao) | `VersiculoUseCase.aleatorio`, `VersiculoReacaoUseCase.minhaReacao`, `alternarLido` | `/v1/versiculo/aleatorio`, `/v1/versiculo-reacao` | Versículo sorteado. O usuário marca como lido, com comentário opcional. |
| — (card) | [dashboard/widgets/musica](../../app/lib/features/dashboard/widgets/musica) | `MusicaUseCase.aleatoria`, `links`, `inspiracao`, `abrirLink` | `/v1/musica/aleatoria` | Música sorteada com artista, gênero e inspiração. Abre o Spotify, Deezer ou Apple Music com o `url_launcher`. |
| `/loggof` | [loggof](../../app/lib/features/loggof) | — | — | Limpa `AuthSession` e `UsuarioSession` e volta para `/home`. |

## Bíblia (`BibliaRouter`)

| Rota | Feature | Use case | Endpoints | Comportamento |
|---|---|---|---|---|
| `/biblia-leitura` | [biblia/biblia_leitura](../../app/lib/features/biblia/biblia_leitura) + [versiculo_indicacao](../../app/lib/features/biblia/versiculo_indicacao) | `BibliaLeituraUseCase`, `VersiculoIndicacaoUseCase`, `VersiculoReacaoUseCase` | `/v1/versao`, `/v1/testamento`, `/v1/livro`, `/v1/biblia/indice`, `/v1/biblia/capitulo`, `/v1/versiculo-reacao/lidos`, `/v1/versiculo-reacao/capitulo` (GET e PUT), `/v1/versiculo-reacao`, `/v1/versiculo-indicacao` | Índice por versão e testamento, com o progresso de leitura de cada livro e capítulo. Na leitura do capítulo, o usuário marca o capítulo ou cada versículo como lido (ícone ao lado da linha; o comentário da reação é mantido), navega entre capítulos e, tocando no texto, indica o versículo com comentário. Tem também o histórico de leitura. |

## Administração

| Rota | Feature | Use case | Endpoints | Comportamento |
|---|---|---|---|---|
| `/menu` | [admin/menu](../../app/lib/features/admin/menu) | `MenuUseCase.getMenus`, `saveMenu`, `deleteMenu` | `/v1/menu` | CRUD de menus. A lista mostra o nível de cada um. |
| `/configuracao` | [admin/configuracao](../../app/lib/features/admin/configuracao) | `ConfiguracaoUseCase` (configuração e itens) | `/v1/configuracao`, `/v1/configuracao-item` | CRUD de configurações e dos itens de cada uma. |
| `/log` | [admin/log](../../app/lib/features/admin/log) | `LogUseCase.getLogs` | `/v1/log` | Lista de logs, com detalhe de cada um. |
| `/notificacao` | [admin/notificacao](../../app/lib/features/admin/notificacao) | `NotificacaoUseCase.getNotificacoes` | `/v1/notificacao` | Lista de notificações, com o log associado. |

## Infraestrutura do app

| Arquivo | Função |
|---|---|
| [`config/dependencies.dart`](../../app/lib/config/dependencies.dart) | Registro dos repositories no `GetIt` |
| [`config/command.dart`](../../app/lib/config/command.dart) | `Command0` / `Command1` |
| [`config/icons_map.dart`](../../app/lib/config/icons_map.dart) | Chave MDI → `IconData` (menus e cards) |
| [`config/app_config.dart`](../../app/lib/config/app_config.dart) | Tema e idioma persistidos |
| [`config/theme_mode_button.dart`](../../app/lib/config/theme_mode_button.dart), [`orientation_button.dart`](../../app/lib/config/orientation_button.dart) | Botões da AppBar |
| [`config/device_info.dart`](../../app/lib/config/device_info.dart) | Informações do dispositivo (a chamada em `main.dart` está comentada) |
| [`l10n/`](../../app/lib/l10n) | `AppLocalizations` e repository de `/v1/traducao` |
