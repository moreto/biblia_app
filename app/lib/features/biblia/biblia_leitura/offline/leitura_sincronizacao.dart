import 'dart:async';
import 'dart:convert';

import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:service/service.dart';

import '../../../../data/local/conectividade.dart';
import '../../../../data/local/leitura_local_store.dart';
import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../../../dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import '../repository/biblia_leitura_repository.dart';
import '../versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import 'falha_api.dart';

/// Envia à API as marcações (lido e indicação) feitas no aparelho e ainda pendentes no [LeituraLocalStore].
///
/// Os repositories recebidos são os que falam direto com a API (não os offline), para a sincronização não gravar
/// de novo no aparelho.
///
/// Quando roda:
/// - ao voltar a conexão ([iniciar] ouve a [Conectividade]);
/// - logo depois de cada marcação feita no aparelho ([agendar]);
/// - quando a leitura abre ou o usuário pede ([sincronizar]).
///
/// Só uma sincronização roda por vez; um pedido no meio dela faz rodar de novo ao final.
///
/// Regras:
/// - cada versículo guarda o estado final (não a sequência de toques), então marcar e desmarcar várias vezes
///   offline vira no máximo uma gravação;
/// - capítulo com todos os versículos pendentes e a mesma marcação vai num só `PUT /versiculo-reacao/capitulo`;
/// - nos demais, as reações do capítulo são consultadas antes, para alterar a que já existe em vez de criar outra
///   (a API não impede reações duplicadas); o comentário da API é mantido, salvo se foi alterado no aparelho;
/// - indicação sem `vindId` consulta a do usuário na API antes de incluir, pelo mesmo motivo;
/// - API inacessível ou sessão vencida param a sincronização e as pendências esperam a próxima;
/// - erro 5xx conta uma tentativa; em [maxTentativas] a alteração é descartada (pode ser um dado que a API nunca
///   aceita);
/// - outros erros (dados recusados pela API) descartam a alteração: o aparelho volta ao estado da API.
class LeituraSincronizacao extends ChangeNotifier {
  LeituraSincronizacao({
    required this._store,
    required this._conectividade,
    required this._bibliaRemoto,
    required this._reacaoRemoto,
    required this._indicacaoRemoto,
    int? Function()? usuarioLogado,
  }) : _usuarioLogado = usuarioLogado ?? (() => AuthSession.instance.userId);

  /// Falhas 5xx seguidas até descartar a alteração.
  static const maxTentativas = 5;

  final LeituraLocalStore _store;
  final Conectividade _conectividade;
  final BibliaLeituraRepository _bibliaRemoto;
  final VersiculoReacaoRepository _reacaoRemoto;
  final VersiculoIndicacaoRepository _indicacaoRemoto;
  final int? Function() _usuarioLogado;

  StreamSubscription<bool>? _assinatura;
  Future<void>? _emAndamento;
  bool _repetir = false;
  bool _descartada = false;

  /// O aparelho tem conexão.
  bool get online => _conectividade.online;

  int _pendentes = 0;

  /// Marcações do usuário logado ainda não enviadas à API.
  int get pendentes => _pendentes;

  bool _sincronizando = false;
  bool get sincronizando => _sincronizando;

  /// Verifica a conexão, passa a sincronizar quando ela volta e já tenta enviar o que estiver pendente.
  Future<void> iniciar() async {
    await _conectividade.verificar();
    _assinatura ??= _conectividade.mudancas.listen((online) {
      notifyListeners();
      if (online) agendar();
    });
    agendar();
  }

  /// Pede uma sincronização sem esperar por ela.
  void agendar() => unawaited(sincronizar());

  /// Envia as pendências do usuário logado. Se já há uma sincronização rodando, devolve a mesma e roda de novo
  /// ao final.
  Future<void> sincronizar() {
    final emAndamento = _emAndamento;
    if (emAndamento != null) {
      _repetir = true;
      return emAndamento;
    }
    return _emAndamento = _rodar().whenComplete(() => _emAndamento = null);
  }

  /// Atualiza [pendentes] a partir do aparelho.
  Future<void> atualizarPendentes() async {
    final usuaId = _usuarioLogado();
    await _contar(usuaId);
  }

  Future<void> _contar(int? usuaId) async {
    var total = 0;
    try {
      total = usuaId == null ? 0 : await _store.contarPendentes(usuaId);
    } catch (error) {
      Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    if (total != _pendentes) {
      _pendentes = total;
      notifyListeners();
    }
  }

  Future<void> _rodar() async {
    do {
      _repetir = false;
      final usuaId = _usuarioLogado();
      await _contar(usuaId);
      if (usuaId == null || _pendentes == 0 || !_conectividade.online) break;

      _sincronizando = true;
      notifyListeners();
      try {
        final continuar = await _sincronizarReacoes(usuaId);
        if (continuar) await _sincronizarIndicacoes(usuaId);
      } catch (error) {
        Log.print(error.toString(), name: kApp, title: 'Erro');
      } finally {
        _sincronizando = false;
      }
      await _contar(usuaId);
      notifyListeners();
    } while (_repetir);
  }

  /// Uma alteração foi descartada desde a última leitura desta flag (a API a recusou). A tela pode recarregar para
  /// mostrar o estado da API.
  bool consumirDescartada() {
    final valor = _descartada;
    _descartada = false;
    return valor;
  }

  /// Trata o erro ao enviar uma alteração. Devolve false quando a sincronização deve parar (API inacessível ou
  /// sessão vencida); senão conta a tentativa ou descarta a alteração com [descartar].
  Future<bool> _tratarErro(
    Exception error,
    Future<int> Function() registrarFalha,
    Future<void> Function() descartar,
  ) async {
    Log.print(error.toString(), name: kApp, title: 'Erro sincronização');
    if (erroServidor(error)) {
      if (await registrarFalha() < maxTentativas) return true;
    } else if (tentarDeNovo(error)) {
      return false;
    }
    await descartar();
    _descartada = true;
    return true;
  }

  /// Devolve false se a sincronização deve parar.
  Future<bool> _sincronizarReacoes(int usuaId) async {
    final pendentes = await _store.reacoesPendentes(usuaId);
    final capitulos = <CoordenadaVersiculo, List<ReacaoLocal>>{};
    for (final reacao in pendentes) {
      capitulos.putIfAbsent(reacao.coordenada, () => []).add(reacao);
    }

    final versoesAlteradas = <int>{};
    for (final MapEntry(key: c, value: grupo) in capitulos.entries) {
      final continuar = await _capituloInteiro(usuaId, c, grupo) ?? await _porVersiculo(usuaId, c, grupo);
      versoesAlteradas.add(c.versaId);
      if (!continuar) {
        await _atualizarLidos(usuaId, versoesAlteradas);
        return false;
      }
    }
    await _atualizarLidos(usuaId, versoesAlteradas);
    return true;
  }

  /// Envia o capítulo num só PUT quando todos os versículos dele estão no [grupo] com a mesma marcação e sem
  /// comentário alterado. Nulo quando não se aplica (segue versículo a versículo).
  Future<bool?> _capituloInteiro(int usuaId, CoordenadaVersiculo c, List<ReacaoLocal> grupo) async {
    final lido = grupo.first.lido;
    if (grupo.any((r) => r.lido != lido || r.comentarioAlterado)) return null;
    final resumo = await _store.resumoCapitulo(c.versaId, c.livrId, c.capiNumero);
    if (resumo == null || resumo.versTotal != grupo.length) return null;

    final result = await _bibliaRemoto.marcarCapitulo(c.versaId, c.livrId, c.capiNumero, lido: lido);
    switch (result) {
      case Ok<int>():
        for (final reacao in grupo) {
          await _store.concluirReacao(
            usuaId,
            reacao.versId,
            versao: reacao.versao,
            vreaId: reacao.vreaId,
            lidoEnviado: lido,
            comentario: reacao.comentario,
          );
        }
        return true;
      case Error<int>(error: final error):
        var continuar = true;
        for (final reacao in grupo) {
          continuar = await _tratarErro(
            error,
            () => _store.registrarFalhaReacao(usuaId, reacao.versId),
            () => _store.descartarReacao(usuaId, reacao.versId, versao: reacao.versao),
          );
          if (!continuar) break;
        }
        return continuar;
    }
  }

  Future<bool> _porVersiculo(int usuaId, CoordenadaVersiculo c, List<ReacaoLocal> grupo) async {
    final consulta = await _bibliaRemoto.reacoesCapitulo(c.versaId, c.livrId, c.capiNumero);
    final Map<int, VersiculoReacaoModel> servidor;
    switch (consulta) {
      case Ok<List<VersiculoReacaoModel>>(value: final lista):
        servidor = {for (final r in lista) r.versId: r};
      case Error<List<VersiculoReacaoModel>>(error: final error):
        var continuar = true;
        for (final reacao in grupo) {
          continuar = await _tratarErro(
            error,
            () => _store.registrarFalhaReacao(usuaId, reacao.versId),
            () => _store.descartarReacao(usuaId, reacao.versId, versao: reacao.versao),
          );
          if (!continuar) break;
        }
        return continuar;
    }

    for (final reacao in grupo) {
      final atual = servidor[reacao.versId];
      final comentario = reacao.comentarioAlterado ? reacao.comentario : atual?.vreaComentario;

      final Result<VersiculoReacaoModel?> result;
      if (atual != null && atual.vreaLido == reacao.lido && atual.vreaComentario == comentario) {
        result = Result.ok(atual);
      } else if (atual != null) {
        result = await _reacaoRemoto.alterar(
          VersiculoReacaoModel(
            vreaId: atual.vreaId,
            versId: reacao.versId,
            usuaId: usuaId,
            vreaComentario: comentario,
            vreaLido: reacao.lido,
          ),
        );
      } else if (!reacao.lido && comentario == null) {
        // Desmarcado e sem reação na API: não há o que gravar.
        result = const Result.ok(null);
      } else {
        result = await _reacaoRemoto.incluir(
          VersiculoReacaoModel(
            versId: reacao.versId,
            usuaId: usuaId,
            vreaComentario: comentario,
            vreaLido: reacao.lido,
          ),
        );
      }

      switch (result) {
        case Ok<VersiculoReacaoModel?>(value: final gravada):
          await _store.concluirReacao(
            usuaId,
            reacao.versId,
            versao: reacao.versao,
            vreaId: gravada?.vreaId ?? atual?.vreaId,
            lidoEnviado: reacao.lido,
            comentario: comentario,
          );
        case Error<VersiculoReacaoModel?>(error: final error):
          final continuar = await _tratarErro(
            error,
            () => _store.registrarFalhaReacao(usuaId, reacao.versId),
            () => _store.descartarReacao(usuaId, reacao.versId, versao: reacao.versao),
          );
          if (!continuar) return false;
      }
    }
    return true;
  }

  /// Atualiza no cache o progresso de leitura das versões alteradas, para ele não ficar para trás se a conexão cair
  /// antes da próxima consulta. Falha aqui não importa: a próxima abertura da leitura consulta de novo.
  Future<void> _atualizarLidos(int usuaId, Set<int> versoes) async {
    for (final versaId in versoes) {
      final result = await _bibliaRemoto.lidos(versaId);
      if (result case Ok<List<CapituloLidoModel>>(value: final lidos)) {
        await _store.salvarCache(
          LeituraLocalStore.chaveLidos(usuaId, versaId),
          jsonEncode(lidos.map((l) => l.toJson()).toList()),
        );
      }
    }
  }

  Future<void> _sincronizarIndicacoes(int usuaId) async {
    for (final indicacao in await _store.indicacoesPendentes(usuaId)) {
      if (!await _enviarIndicacao(usuaId, indicacao)) return;
    }
  }

  /// Devolve false se a sincronização deve parar.
  Future<bool> _enviarIndicacao(int usuaId, IndicacaoLocal indicacao) async {
    Future<bool> falhou(Exception error) => _tratarErro(
      error,
      () => _store.registrarFalhaIndicacao(usuaId, indicacao.versId),
      () => _store.descartarIndicacao(usuaId, indicacao.versId, versao: indicacao.versao),
    );

    var vindId = indicacao.vindId;
    if (vindId == null) {
      final consulta = await _indicacaoRemoto.indicacoes(indicacao.versId);
      switch (consulta) {
        case Ok<List<VersiculoIndicacaoModel>>(value: final lista):
          for (final i in lista) {
            if (i.usuaId == usuaId && (i.vindId ?? 0) > (vindId ?? 0)) vindId = i.vindId;
          }
        case Error<List<VersiculoIndicacaoModel>>(error: final error):
          return falhou(error);
      }
    }

    if (indicacao.excluida) {
      if (vindId != null) {
        final result = await _indicacaoRemoto.excluir(vindId);
        // Já removida na API (404): o objetivo foi atingido.
        if (result case Error(error: final error) when !(error is HttpServiceException && error.code == 404)) {
          return falhou(error);
        }
      }
      await _store.concluirIndicacao(usuaId, indicacao.versId, versao: indicacao.versao, vindId: null, removida: true);
      return true;
    }

    final model = VersiculoIndicacaoModel(
      vindId: vindId,
      versId: indicacao.versId,
      usuaId: usuaId,
      vindComentario: indicacao.comentario,
    );
    final result = vindId == null ? await _indicacaoRemoto.incluir(model) : await _indicacaoRemoto.alterar(model);
    switch (result) {
      case Ok<VersiculoIndicacaoModel>(value: final gravada):
        await _store.concluirIndicacao(
          usuaId,
          indicacao.versId,
          versao: indicacao.versao,
          vindId: gravada.vindId ?? vindId,
        );
        return true;
      case Error<VersiculoIndicacaoModel>(error: final error):
        return falhou(error);
    }
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }
}
