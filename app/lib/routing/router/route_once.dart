import 'package:flutter/widgets.dart';

/// Cria a tela da rota uma única vez, enquanto a rota estiver na pilha.
///
/// O GoRouter chama o `builder` das rotas da pilha de novo a cada navegação (`push`, `pop`, `go`). Quando o
/// `builder` cria viewmodels que carregam dados no construtor, isso refaz as chamadas de API da tela que está por
/// baixo. Com [RouteOnce], [create] roda só na primeira vez e a mesma tela (com os mesmos viewmodels) é reaproveitada.
class RouteOnce extends StatefulWidget {
  const RouteOnce({super.key, required this.create});

  final Widget Function() create;

  @override
  State<RouteOnce> createState() => _RouteOnceState();
}

class _RouteOnceState extends State<RouteOnce> {
  late final Widget _child = widget.create();

  @override
  Widget build(BuildContext context) => _child;
}
