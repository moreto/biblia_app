import 'package:commons/commons.dart';

import '../../../data/model/menu/menu_model.dart';
import '../../../routing/routes.dart';
import '../repository/dashboard_repository.dart';

/// Regras da dashboard:
/// - [menu] carrega os menus de `/v1/menu`;
/// - [mensagensNaoLidas] conta as mensagens não lidas e não arquivadas (badge do menu de mensagens); o total nunca é
///   negativo;
/// - [contemMensagens] indica se o menu leva à tela de mensagens (rota [Routes.mensagemLista]) por ele mesmo ou por
///   um filho, em qualquer nível: é nesse menu que o badge aparece;
/// - [rotuloBadge] é o texto do badge: nulo (sem badge) quando não há não lidas e "99+" acima de 99.
class DashboardUseCase {
  DashboardUseCase({required this.dashboardRepository}) {
    Log.print(super.runtimeType);
  }

  final DashboardRepository dashboardRepository;

  /// Maior quantidade mostrada por extenso no badge; acima dela, "99+".
  static const kBadgeMaximo = 99;

  Future<Result<MenuModel>> menu() async {
    final result = await dashboardRepository.menu();
    switch (result) {
      case Ok<MenuModel>():
        return Result.ok(result.value);
      case Error<MenuModel>():
        return Result.error(result.error);
    }
  }

  Future<Result<int>> mensagensNaoLidas() async {
    final result = await dashboardRepository.mensagensNaoLidas();
    switch (result) {
      case Ok<int>(value: final total):
        return Result.ok(total < 0 ? 0 : total);
      case Error<int>():
        return result;
    }
  }

  static bool contemMensagens(Menu menu) =>
      menu.menuRota == Routes.mensagemLista || (menu.children ?? const []).any(contemMensagens);

  static String? rotuloBadge(int total) {
    if (total <= 0) return null;
    return total > kBadgeMaximo ? '$kBadgeMaximo+' : '$total';
  }
}
