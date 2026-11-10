# Mapa do código

Para cada tela: rota, feature, use case e endpoints. Os caminhos de feature são relativos a `app/lib/features/`. Os endpoints estão em `ApiCore` ([`commons/lib/api/api_core.dart`](../../commons/lib/api/api_core.dart)), com o prefixo `/api`. A `biblia_api` documenta cada endpoint em `files/docs/mapa.md`.

## Acesso (`AccessRouter`)

| Rota | Feature | Use case | Endpoints | Comportamento |
|---|---|---|---|---|
| — (abertura) | [access/configuracao_app](../../app/lib/features/access/configuracao_app) | `ConfiguracaoAppUseCase.carregar`, `cryptKeyB64` | `/v1/configuracao-app` (público, sem headers de acesso) | Chamado no `main`, antes do `runApp`. Valida `kCryptKeyB64` (AES-256, 32 bytes) e grava a `AppSession`. Login e registro usam o mesmo use case para obter a chave. |
| `/home` (inicial) | [access/home](../../app/lib/features/access/home) | `HomeUseCase.healt` | `ApiCore.healt` (`/api`) | Verifica se a API responde. A `NavigationBar` tem tema, idioma e, à direita, o login. |
| — (card) | [access/home/widgets/funcionalidade](../../app/lib/features/access/home/widgets/funcionalidade) | `FuncionalidadeUseCase.listar` | `/v1/funcionalidade` (público, sem headers de acesso) | Lista as funcionalidades do app na ordem da API. As inativas aparecem esmaecidas, com o selo "Em breve". |
| `/login` | [access/login](../../app/lib/features/access/login) | `LoginUseCase.login`, `otpSend`, `otpVerify` | `/v1/acesso/login`, `/v1/otp/send`, `/v1/otp/verify` | Valida e-mail e código de 6 dígitos, criptografa a senha (AES-GCM, chave de `AppSession`) e grava `AuthSession`. Depois vai para `/dashboard`. O link "Criar conta" abre `/registro`. |
| `/registro` | [access/registro](../../app/lib/features/access/registro) | `RegistroUseCase.registrar`, `ativar` | `/v1/acesso/registro`, `/v1/usuario-ativacao/confirmar` (públicos) | Valida e-mail, senha (mínimo 6) e confirmação, criptografa a senha e cria o usuário inativo. Depois pede o código de 6 dígitos enviado ao e-mail e ativa a conta. Volta ao login com o e-mail preenchido. |

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
| `/biblia-leitura` | [biblia/biblia_leitura](../../app/lib/features/biblia/biblia_leitura) + [versiculo_indicacao](../../app/lib/features/biblia/versiculo_indicacao) | `BibliaLeituraUseCase`, `VersiculoIndicacaoUseCase`, `VersiculoIndicacaoUsuarioUseCase`, `VersiculoReacaoUseCase` | `/v1/versao`, `/v1/testamento`, `/v1/livro`, `/v1/biblia/indice`, `/v1/biblia/capitulo`, `/v1/versiculo-reacao/lidos`, `/v1/versiculo-reacao/capitulo` (GET e PUT), `/v1/versiculo-reacao`, `/v1/versiculo-indicacao`, `/v1/versiculo-indicacao/capitulo`, `/v1/versiculo-indicacao-usuario`, `/v1/usuario/busca` | Índice por versão e testamento, com o progresso de leitura de cada livro e capítulo. Na leitura do capítulo, o usuário navega entre capítulos e marca o capítulo ou cada versículo como lido; cada marcação mostra uma confirmação (SnackBar) e, ao completar o capítulo pelo último versículo, avisa que ele foi concluído. Tocar na linha do versículo só a destaca como indicativo de leitura (visual, não grava; some ao trocar de capítulo). Ao lado de cada versículo ficam dois ícones empilhados que mudam conforme o estado: em cima, lido/não lido (o comentário da reação é mantido); embaixo, comentário e indicação, com três estados (não indicado, indicado sem comentário e com comentário, a partir das indicações do usuário no capítulo). Só esse ícone abre a folha de indicação. Na folha, o usuário indica o versículo com comentário e, depois de indicar, busca usuários por nome ou nome de usuário para recebê-la ("Indicar para"), adicionando e removendo destinatários. Tem também o histórico de leitura. |

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
| [`config/app_config.dart`](../../app/lib/config/app_config.dart) | Tema, idioma e versão da Bíblia persistidos |
| [`config/versao_preferencia.dart`](../../app/lib/config/versao_preferencia.dart) | Interface da versão da Bíblia escolhida (implementada por `AppConfig`) |
| [`routing/auth_guard.dart`](../../app/lib/routing/auth_guard.dart) | Rotas públicas e redirecionamento conforme a sessão |
| [`config/theme_mode_button.dart`](../../app/lib/config/theme_mode_button.dart), [`orientation_button.dart`](../../app/lib/config/orientation_button.dart) | Botões da AppBar |
| [`config/device_info.dart`](../../app/lib/config/device_info.dart) | Informações do dispositivo (a chamada em `main.dart` está comentada) |
| [`l10n/`](../../app/lib/l10n) | `AppLocalizations` e repository de `/v1/traducao` |
