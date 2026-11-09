import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../../data/model/musica/musica_model.dart';
import 'musica_repository.dart';

class MusicaRepositoryImpl implements MusicaRepository {
  @override
  Future<Result<MusicaModel>> aleatoria() async {
    try {
      final response = await DioProvider.of(ApiCore.musicaAleatoria).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is Map:
          return Result.ok(MusicaModel.fromJson(Map<String, dynamic>.from(value)));
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoMusicaInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoMusicaInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
