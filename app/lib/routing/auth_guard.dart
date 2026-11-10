import 'routes.dart';

/// Rotas acessíveis sem login. Todas as demais exigem sessão
/// (as APIs `loggedArea` falham com `headerInvalido` sem token).
const Set<String> kPublicRoutes = {Routes.splash, Routes.home, Routes.login, Routes.registro};

/// Rotas de acesso que não fazem sentido para quem já está logado.
const Set<String> _accessRoutes = {Routes.splash, Routes.home, Routes.login};

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
