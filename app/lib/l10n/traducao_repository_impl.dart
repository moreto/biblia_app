import 'package:app/data/model/traducao_model.dart';
import 'package:commons/api_core.dart';
import 'package:commons/result.dart';
import 'package:service/api/dio_provider.dart';
import 'package:service/api/enum.dart';

import 'traducao_repository.dart';

class TraducaoRepositoryImpl implements TraducaoRepository {
  @override
  Future<Result<List<TraducaoModel>>> get() async {
    try {
      final response = await DioProvider.of(ApiCore.traducao).request(verb: Verb.get);
      switch (response) {
        case Ok(value: final value) when value is List:
          final translations = value
              .map((item) => TraducaoModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(growable: false);
          return Result.ok(translations);
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(Exception('Resposta de traduções em formato inválido.'));
      }
    } catch (ex) {
      return Result.error(ex is Exception ? ex : Exception(ex.toString()));
    }
  }
}
