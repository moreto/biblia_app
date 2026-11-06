import 'package:go_router/go_router.dart';

import 'routes.dart';

GoRouter router() => GoRouter(
  initialLocation: Routes.home,
  // debugLogDiagnostics: true,
  // redirect: _redirect,
  // refreshListenable: authRepository,

  routes: [
    //...AccessRouter.routes,
  ],
);
