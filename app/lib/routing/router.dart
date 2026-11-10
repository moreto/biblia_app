import 'package:app/routing/router/common_router.dart';
import 'package:commons/commons.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import 'auth_guard.dart';
import 'router/access_router.dart';
import 'router/biblia_router.dart';
import 'router/configuracao_router.dart';
import 'router/log_router.dart';
import 'router/menu_router.dart';
import 'router/notificacao_router.dart';
import 'routes.dart';

GoRouter router() => GoRouter(
  initialLocation: Routes.home,
  // debugLogDiagnostics: true,
  redirect: (BuildContext context, GoRouterState state) {
    Log.print(state.uri.toString(), title: 'Route', name: kApp);
    return authRedirect(path: state.uri.path, isLogged: AuthSession.instance.isLogged);
  },
  // refreshListenable: authRepository,
  routes: [
    ...AccessRouter.routes,
    ...CommonRouter.routes,
    ...LogRouter.routes,
    ...NotificacaoRouter.routes,
    ...ConfiguracaoRouter.routes,
    ...MenuRouter.routes,
    ...BibliaRouter.routes,
  ],
);
