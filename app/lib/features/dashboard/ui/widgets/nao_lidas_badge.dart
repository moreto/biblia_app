import 'package:flutter/material.dart';

/// Badge de mensagens não lidas sobre o ícone de um menu (Material 3 [Badge]).
/// Sem [rotulo] (nenhuma não lida), mostra só o [child].
class NaoLidasBadge extends StatelessWidget {
  const NaoLidasBadge({super.key, required this.rotulo, required this.child});

  /// Texto do badge (ex.: "3", "99+"); nulo esconde o badge.
  final String? rotulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final texto = rotulo;
    if (texto == null) return child;
    return Badge(label: Text(texto), child: child);
  }
}
