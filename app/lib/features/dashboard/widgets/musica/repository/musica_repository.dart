import 'package:commons/commons.dart';

import '../../../../../data/model/musica/musica_model.dart';

abstract class MusicaRepository {
  /// Uma música sorteada pela API (`GET /v1/musica/aleatoria`); cada chamada faz um novo sorteio.
  Future<Result<MusicaModel>> aleatoria();
}
