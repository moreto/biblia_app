import 'package:commons/commons.dart';

import '../../../data/model/menu/menu_model.dart';

abstract class DashboardRepository {
  Future<Result<MenuModel>> menu();
}
