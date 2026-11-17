import 'routes.dart';

/// Rotas acessíveis sem login. Todas as demais exigem sessão
/// (as APIs `loggedArea` falham com `headerInvalido` sem token).
/// `/` (splash) não tem tela própria: fica fora daqui para ir à home (ou à dashboard, se logado).
/// `/biblia-leitura` é pública: sem login, a leitura funciona sem progresso, marcações e indicações.
const Set<String> kPublicRoutes = {Routes.home, Routes.homeOld, Routes.login, Routes.registro, Routes.bibliaLeitura};

/// Rotas de acesso que não fazem sentido para quem já está logado.
const Set<String> _accessRoutes = {Routes.splash, Routes.home, Routes.homeOld, Routes.login};

/// Decide o redirecionamento do GoRouter a partir da rota pedida e da sessão.
/// Retorna `null` quando a navegação pode seguir.
String? authRedirect({required String path, required bool isLogged}) {
  if (!isLogged) {
    return kPublicRoutes.contains(path) ? null : Routes.home;
  }
  if (_accessRoutes.contains(path)) {
    return Routes.dashboard;
  }
  return null;
}
