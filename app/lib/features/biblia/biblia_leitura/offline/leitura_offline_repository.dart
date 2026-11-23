import 'dart:convert';

import 'package:commons/commons.dart';
import 'package:service/service.dart';

import '../../../../data/local/conectividade.dart';
import '../../../../data/local/leitura_local_store.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import 'falha_api.dart';

/// Busca na API os versículos de um livro da versão.
typedef BuscarLivro = Future<Result<List<VersiculoTextoModel>>> Function(int versaId, int livrId);

/// Versões da Bíblia baixadas para leitura sem conexão.
abstract class LeituraOfflineRepository {
  /// `versaId` das versões baixadas por inteiro.
  Future<Set<int>> versoesBaixadas();

  /// Baixa o texto da versão, livro a livro (`GET /v1/biblia/livro/:versaId/:livrId`), informando o andamento em
  /// [progresso] (livros prontos e total). Se parar no meio, o próximo pedido continua dos livros que faltam.
  Future<Result<void>> baixarVersao(int versaId, List<int> livrIds, {void Function(int prontos, int total)? progresso});

  /// Apaga do aparelho o texto da versão.
  Future<Result<void>> removerVersao(int versaId);
}

class LeituraOfflineRepositoryImpl implements LeituraOfflineRepository {
  LeituraOfflineRepositoryImpl({required this.store, required this.conectividade, BuscarLivro? buscarLivro})
    : _buscarLivro = buscarLivro ?? _livroApi;

  final LeituraLocalStore store;
  final Conectividade conectividade;
  final BuscarLivro _buscarLivro;

  static String _chaveAndamento(int versaId) => 'download:$versaId';

  @override
  Future<Set<int>> versoesBaixadas() async {
    try {
      return await store.versoesBaixadas();
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro banco local');
      return const {};
    }
  }

  @override
  Future<Result<void>> baixarVersao(
    int versaId,
    List<int> livrIds, {
    void Function(int prontos, int total)? progresso,
  }) async {
    if (!conectividade.online) return Result.error(semConexao());
    try {
      final chave = _chaveAndamento(versaId);
      final salvo = await store.lerCache(chave);
      final prontos = <int>{if (salvo != null) ...(jsonDecode(salvo) as List).cast<int>()};
      progresso?.call(prontos.intersection(livrIds.toSet()).length, livrIds.length);

      for (final livrId in livrIds) {
        if (prontos.contains(livrId)) continue;
        final result = await _buscarLivro(versaId, livrId);
        switch (result) {
          case Ok<List<VersiculoTextoModel>>(value: final versiculos):
            await store.salvarVersiculos(versaId, versiculos);
            prontos.add(livrId);
            await store.salvarCache(chave, jsonEncode(prontos.toList()));
            progresso?.call(prontos.intersection(livrIds.toSet()).length, livrIds.length);
          case Error<List<VersiculoTextoModel>>(error: final error):
            return Result.error(error);
        }
      }

      await store.marcarVersaoBaixada(versaId);
      await store.removerCache(chave);
      return const Result.ok(null);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro download');
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  @override
  Future<Result<void>> removerVersao(int versaId) async {
    try {
      await store.removerVersao(versaId);
      await store.removerCache(_chaveAndamento(versaId));
      return const Result.ok(null);
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }

  static Future<Result<List<VersiculoTextoModel>>> _livroApi(int versaId, int livrId) async {
    try {
      final response = await DioProvider.of(ApiCore.bibliaLivro)
          .request(verb: Verb.get, pathParam: '$versaId/$livrId', timeout: 90);
      switch (response) {
        case Ok(value: final value) when value is List:
          return Result.ok(
            value
                .map((item) {
                  if (item is! Map) throw const FormatException('formatoLeituraInvalido');
                  return VersiculoTextoModel.fromJson(Map<String, dynamic>.from(item));
                })
                .toList(growable: false),
          );
        case Error(error: final error):
          return Result.error(error);
        default:
          return Result.error(HandledException(message: 'respostaApiInvalida'));
      }
    } on FormatException {
      return Result.error(HandledException(message: 'formatoLeituraInvalido'));
    } on TypeError {
      return Result.error(HandledException(message: 'formatoLeituraInvalido'));
    } catch (error) {
      return Result.error(error is Exception ? error : Exception(error.toString()));
    }
  }
}
