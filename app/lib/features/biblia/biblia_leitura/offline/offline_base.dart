import 'dart:convert';

import 'package:commons/commons.dart';

import '../../../../data/local/conectividade.dart';
import '../../../../data/local/leitura_local_store.dart';
import 'falha_api.dart';
import 'leitura_sincronizacao.dart';

/// Base dos repositories offline da leitura: decoram o repository da API com o [LeituraLocalStore].
///
/// - [remoto] só chama a API se o aparelho tem conexão; sem ela devolve [semConexao] na hora, sem esperar o
///   timeout;
/// - [listaComCache] guarda cada resposta da API e, se ela não responder, devolve a última guardada;
/// - [local] protege as operações no banco local: se ele falhar, o repository segue só com a API.
abstract class OfflineBase {
  OfflineBase({
    required this.store,
    required this.conectividade,
    required this.sincronizacao,
    int? Function()? usuarioLogado,
    DateTime Function()? agora,
  }) : usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId),
       agora = agora ?? DateTime.now;

  final LeituraLocalStore store;
  final Conectividade conectividade;
  final LeituraSincronizacao sincronizacao;
  final int? Function() usuarioLogado;
  final DateTime Function() agora;

  int get agoraMs => agora().millisecondsSinceEpoch;

  Future<Result<T>> remoto<T>(Future<Result<T>> Function() chamada) async =>
      conectividade.online ? chamada() : Result.error(semConexao());

  /// Executa [operacao] no banco local; erro do banco devolve nulo (e é registrado no log).
  Future<T?> local<T>(Future<T> Function() operacao) async {
    try {
      return await operacao();
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro banco local');
      return null;
    }
  }

  /// Lista da API com cache em [chave]. Sem resposta da API e sem cache, devolve o erro da API.
  Future<Result<List<T>>> listaComCache<T>(
    String chave,
    Future<Result<List<T>>> Function() chamada,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final result = await remoto(chamada);
    switch (result) {
      case Ok<List<T>>(value: final lista):
        await local(() => store.salvarCache(chave, jsonEncode(lista.map(toJson).toList())));
        return result;
      case Error<List<T>>():
        final salva = await lerLista(chave, fromJson);
        return salva == null ? result : Result.ok(salva);
    }
  }

  /// Lista guardada em [chave]; nula se não há cache ou se ele está corrompido.
  Future<List<T>?> lerLista<T>(String chave, T Function(Map<String, dynamic>) fromJson) async {
    final texto = await local(() => store.lerCache(chave));
    if (texto == null) return null;
    try {
      return (jsonDecode(texto) as List)
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro cache');
      return null;
    }
  }
}
