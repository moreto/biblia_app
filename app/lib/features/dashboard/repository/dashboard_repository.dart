import 'package:commons/commons.dart';

import '../../../data/model/healt_model.dart';

abstract class DashboardRepository {
  Future<Result<HealtModel>> healt();
}
