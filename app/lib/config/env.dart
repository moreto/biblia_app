/// Variáveis do `app/.env`, lidas no build com `--dart-define-from-file=.env` (já configurado no
/// `.vscode/launch.json`). Sem o arquivo ou sem a variável, ficam vazias.
///
/// Copie `app/.env.example` para `app/.env` e preencha só o que precisar. O `.env` fica fora do git.
abstract final class Env {
  /// Rota em que o app abre no lugar da `/home` (ex.: `/biblia-leitura`, `/dashboard`). Vazia abre a home.
  ///
  /// Serve para desenvolvimento: ir direto à tela em que se está trabalhando. O guard continua valendo, então uma
  /// rota da área logada sem login volta para a `/home`.
  static const rotaInicial = String.fromEnvironment('ROTA_INICIAL');
}
