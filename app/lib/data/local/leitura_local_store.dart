import 'package:sqflite/sqflite.dart';

import '../model/biblia/versiculo_indicacao_model.dart';
import '../model/biblia/versiculo_texto_model.dart';
import '../model/versiculo/versiculo_reacao_model.dart';
import 'banco_local.dart';

/// Capítulo de um versículo: versão, livro e número do capítulo.
typedef CoordenadaVersiculo = ({int versaId, int livrId, int capiNumero});

/// Marcação de lido de um versículo pelo usuário, como está no aparelho (tabela `reacao`).
class ReacaoLocal {
  const ReacaoLocal({
    required this.versId,
    required this.coordenada,
    this.vreaId,
    required this.lido,
    required this.lidoServidor,
    this.comentario,
    required this.comentarioAlterado,
    required this.pendente,
    required this.versao,
    required this.tentativas,
    this.alteradoEm,
  });

  final int versId;
  final CoordenadaVersiculo coordenada;

  /// Id da reação na API; nulo enquanto ela não foi gravada lá (ou não se sabe qual é).
  final int? vreaId;
  final bool lido;

  /// Último estado conhecido na API.
  final bool lidoServidor;
  final String? comentario;

  /// O comentário foi alterado no aparelho e deve ser enviado à API.
  final bool comentarioAlterado;

  /// Alterada no aparelho e ainda não enviada à API.
  final bool pendente;
  final int versao;
  final int tentativas;
  final DateTime? alteradoEm;

  VersiculoReacaoModel toModel(int usuaId) =>
      VersiculoReacaoModel(vreaId: vreaId, versId: versId, usuaId: usuaId, vreaComentario: comentario, vreaLido: lido);

  factory ReacaoLocal._fromRow(Map<String, Object?> row) => ReacaoLocal(
    versId: row['vers_id']! as int,
    coordenada: _coordenada(row),
    vreaId: row['vrea_id'] as int?,
    lido: row['lido'] == 1,
    lidoServidor: row['lido_servidor'] == 1,
    comentario: row['comentario'] as String?,
    comentarioAlterado: row['comentario_alterado'] == 1,
    pendente: row['pendente'] == 1,
    versao: row['versao']! as int,
    tentativas: row['tentativas']! as int,
    alteradoEm: _data(row['alterado_em']),
  );
}

/// Indicação de um versículo pelo usuário, como está no aparelho (tabela `indicacao`).
class IndicacaoLocal {
  const IndicacaoLocal({
    required this.versId,
    required this.coordenada,
    this.vindId,
    this.comentario,
    required this.excluida,
    required this.pendente,
    required this.versao,
    required this.tentativas,
  });

  final int versId;
  final CoordenadaVersiculo coordenada;

  /// Id da indicação na API; nulo enquanto ela não foi gravada lá.
  final int? vindId;
  final String? comentario;

  /// O usuário removeu a indicação no aparelho; a linha some depois de sincronizar.
  final bool excluida;
  final bool pendente;
  final int versao;
  final int tentativas;

  /// Id mostrado ao app: o da API ou, enquanto ela não foi gravada lá, o provisório `-versId`.
  int get vindIdOuProvisorio => vindId ?? -versId;

  VersiculoIndicacaoModel toModel(int usuaId) =>
      VersiculoIndicacaoModel(vindId: vindIdOuProvisorio, versId: versId, usuaId: usuaId, vindComentario: comentario);

  factory IndicacaoLocal._fromRow(Map<String, Object?> row) => IndicacaoLocal(
    versId: row['vers_id']! as int,
    coordenada: _coordenada(row),
    vindId: row['vind_id'] as int?,
    comentario: row['comentario'] as String?,
    excluida: row['excluida'] == 1,
    pendente: row['pendente'] == 1,
    versao: row['versao']! as int,
    tentativas: row['tentativas']! as int,
  );
}

CoordenadaVersiculo _coordenada(Map<String, Object?> row) =>
    (versaId: row['versa_id']! as int, livrId: row['livr_id']! as int, capiNumero: row['capi_numero']! as int);

DateTime? _data(Object? valor) => valor is int && valor > 0 ? DateTime.fromMillisecondsSinceEpoch(valor) : null;

int _bool(bool valor) => valor ? 1 : 0;

/// Acesso ao [BancoLocal] da leitura offline: cache das respostas da API, texto da Bíblia e as marcações (lido e
/// indicação) do usuário, com o controle do que ainda falta enviar à API.
///
/// Regras das marcações (tabelas `reacao` e `indicacao`, uma linha por usuário e versículo):
/// - gravar no aparelho marca a linha como pendente e aumenta a `versao`;
/// - a resposta da API ([mesclarReacoesServidor] / [mesclarIndicacoesServidor]) nunca sobrescreve uma linha
///   pendente, nem uma sincronizada depois que a consulta começou (`inicio`), para uma resposta antiga não desfazer
///   o que acabou de ser enviado;
/// - a sincronização conclui a linha ([concluirReacao] / [concluirIndicacao]) só se a `versao` não mudou; se o
///   usuário alterou de novo no meio, ela continua pendente.
class LeituraLocalStore {
  LeituraLocalStore(this._banco, {DateTime Function()? agora}) : _agora = agora ?? DateTime.now;

  final BancoLocal _banco;
  final DateTime Function() _agora;

  int get _agoraMs => _agora().millisecondsSinceEpoch;

  // ---------------------------------------------------------------------------------------------------------------
  // Cache das respostas da API

  Future<String?> lerCache(String chave) async {
    final db = await _banco.db;
    final rows = await db.query('cache', columns: ['valor'], where: 'chave = ?', whereArgs: [chave]);
    return rows.isEmpty ? null : rows.first['valor'] as String?;
  }

  Future<void> salvarCache(String chave, String valor) async {
    final db = await _banco.db;
    await db.insert('cache', {
      'chave': chave,
      'valor': valor,
      'atualizado_em': _agoraMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removerCache(String chave) async {
    final db = await _banco.db;
    await db.delete('cache', where: 'chave = ?', whereArgs: [chave]);
  }

  /// Prefixo das chaves de cache com dados do usuário (progresso de leitura, indicações).
  static String prefixoUsuario(int usuaId) => 'u$usuaId:';

  /// Progresso de leitura do usuário na versão, como a API devolveu (sem as alterações pendentes).
  static String chaveLidos(int usuaId, int versaId) => '${prefixoUsuario(usuaId)}lidos:$versaId';

  /// Indicações de todos os usuários ao versículo, como a API devolveu.
  static String chaveIndicacoes(int usuaId, int versId) => '${prefixoUsuario(usuaId)}indicacoes:$versId';

  // ---------------------------------------------------------------------------------------------------------------
  // Texto da Bíblia

  /// Grava (ou substitui) os versículos da versão [versaId].
  Future<void> salvarVersiculos(int versaId, List<VersiculoTextoModel> versiculos) async {
    if (versiculos.isEmpty) return;
    final db = await _banco.db;
    final batch = db.batch();
    for (final v in versiculos) {
      batch.insert('versiculo', {
        'vers_id': v.versId,
        'versa_id': versaId,
        'livr_id': v.livrId,
        'livr_nome': v.livrNome,
        'capi_numero': v.capiNumero,
        'vers_numero': v.versNumero,
        'vers_texto': v.versTexto,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Versículos do capítulo guardados no aparelho, em ordem; vazia se o capítulo não está salvo.
  Future<List<VersiculoTextoModel>> versiculosDoCapitulo(int versaId, int livrId, int capiNumero) async {
    final db = await _banco.db;
    final rows = await db.query(
      'versiculo',
      where: 'versa_id = ? AND livr_id = ? AND capi_numero = ?',
      whereArgs: [versaId, livrId, capiNumero],
      orderBy: 'vers_numero',
    );
    return [
      for (final row in rows)
        VersiculoTextoModel(
          versId: row['vers_id']! as int,
          versNumero: row['vers_numero']! as int,
          versTexto: row['vers_texto']! as String,
          livrId: row['livr_id']! as int,
          livrNome: row['livr_nome']! as String,
          capiNumero: row['capi_numero']! as int,
        ),
    ];
  }

  /// Capítulo do versículo [versId], se o texto dele está no aparelho.
  Future<CoordenadaVersiculo?> coordenada(int versId) async {
    final db = await _banco.db;
    final rows = await db.query(
      'versiculo',
      columns: ['versa_id', 'livr_id', 'capi_numero'],
      where: 'vers_id = ?',
      whereArgs: [versId],
    );
    return rows.isEmpty ? null : _coordenada(rows.first);
  }

  /// Nome do livro e quantidade de versículos do capítulo salvo; nulo se o capítulo não está no aparelho.
  Future<({String livrNome, int versTotal})?> resumoCapitulo(int versaId, int livrId, int capiNumero) async {
    final db = await _banco.db;
    final rows = await db.rawQuery(
      'SELECT MIN(livr_nome) AS livr_nome, COUNT(*) AS total FROM versiculo '
      'WHERE versa_id = ? AND livr_id = ? AND capi_numero = ?',
      [versaId, livrId, capiNumero],
    );
    final total = rows.first['total'] as int? ?? 0;
    if (total == 0) return null;
    return (livrNome: rows.first['livr_nome']! as String, versTotal: total);
  }

  Future<void> marcarVersaoBaixada(int versaId) async {
    final db = await _banco.db;
    await db.insert('versao_baixada', {
      'versa_id': versaId,
      'baixada_em': _agoraMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Set<int>> versoesBaixadas() async {
    final db = await _banco.db;
    final rows = await db.query('versao_baixada', columns: ['versa_id']);
    return {for (final row in rows) row['versa_id']! as int};
  }

  /// Apaga o texto da versão do aparelho (inclusive os capítulos abertos antes do download).
  Future<void> removerVersao(int versaId) async {
    final db = await _banco.db;
    await db.transaction((txn) async {
      await txn.delete('versiculo', where: 'versa_id = ?', whereArgs: [versaId]);
      await txn.delete('versao_baixada', where: 'versa_id = ?', whereArgs: [versaId]);
    });
  }

  // ---------------------------------------------------------------------------------------------------------------
  // Marcação de lido (reações)

  Future<List<ReacaoLocal>> reacoesDoCapitulo(int usuaId, int versaId, int livrId, int capiNumero) async {
    final db = await _banco.db;
    final rows = await db.query(
      'reacao',
      where: 'usua_id = ? AND versa_id = ? AND livr_id = ? AND capi_numero = ?',
      whereArgs: [usuaId, versaId, livrId, capiNumero],
      orderBy: 'vers_id',
    );
    return rows.map(ReacaoLocal._fromRow).toList(growable: false);
  }

  Future<ReacaoLocal?> reacao(int usuaId, int versId) => _reacao(null, usuaId, versId);

  Future<ReacaoLocal?> _reacao(DatabaseExecutor? executor, int usuaId, int versId) async {
    final db = executor ?? await _banco.db;
    final rows = await db.query('reacao', where: 'usua_id = ? AND vers_id = ?', whereArgs: [usuaId, versId]);
    return rows.isEmpty ? null : ReacaoLocal._fromRow(rows.first);
  }

  /// Grava no aparelho a marcação de lido do versículo, como pendente. [comentario] só é gravado com
  /// [comentarioAlterado]; senão o comentário guardado (o da API) é mantido.
  Future<ReacaoLocal> gravarReacao(
    int usuaId,
    int versId,
    CoordenadaVersiculo coordenada, {
    required bool lido,
    String? comentario,
    bool comentarioAlterado = false,
  }) async {
    final db = await _banco.db;
    return db.transaction((txn) async {
      await _gravarReacao(txn, usuaId, versId, coordenada, lido, comentario, comentarioAlterado);
      return (await _reacao(txn, usuaId, versId))!;
    });
  }

  /// Grava no aparelho, como pendentes, a mesma marcação de lido para todos os [versIds] do capítulo.
  Future<void> gravarReacoesCapitulo(
    int usuaId,
    CoordenadaVersiculo coordenada,
    List<int> versIds, {
    required bool lido,
  }) async {
    final db = await _banco.db;
    await db.transaction((txn) async {
      for (final versId in versIds) {
        await _gravarReacao(txn, usuaId, versId, coordenada, lido, null, false);
      }
    });
  }

  Future<void> _gravarReacao(
    Transaction txn,
    int usuaId,
    int versId,
    CoordenadaVersiculo c,
    bool lido,
    String? comentario,
    bool comentarioAlterado,
  ) async {
    final agora = _agoraMs;
    final atualizadas = await txn.rawUpdate(
      'UPDATE reacao SET lido = ?, pendente = 1, versao = versao + 1, tentativas = 0, alterado_em = ?, '
      'comentario = CASE WHEN ? = 1 THEN ? ELSE comentario END, '
      'comentario_alterado = CASE WHEN ? = 1 THEN 1 ELSE comentario_alterado END '
      'WHERE usua_id = ? AND vers_id = ?',
      [_bool(lido), agora, _bool(comentarioAlterado), comentario, _bool(comentarioAlterado), usuaId, versId],
    );
    if (atualizadas > 0) return;
    await txn.insert('reacao', {
      'usua_id': usuaId,
      'vers_id': versId,
      'versa_id': c.versaId,
      'livr_id': c.livrId,
      'capi_numero': c.capiNumero,
      'lido': _bool(lido),
      'lido_servidor': 0,
      'comentario': comentarioAlterado ? comentario : null,
      'comentario_alterado': _bool(comentarioAlterado),
      'pendente': 1,
      'versao': 1,
      'alterado_em': agora,
    });
  }

  /// Junta ao aparelho as reações do usuário devolvidas pela API para o capítulo [coordenada] (uma por versículo,
  /// a mais recente). Com [apenasVersId], a resposta é só desse versículo e só ele é conferido.
  ///
  /// Linhas sem pendência recebem o estado da API (e são apagadas se a API não tem reação); linhas pendentes só
  /// atualizam o que se sabe da API (`vrea_id`, `lido_servidor` e o comentário, se não foi alterado no aparelho).
  /// Linhas sincronizadas depois de [inicio] (ms) ficam como estão.
  Future<void> mesclarReacoesServidor(
    int usuaId,
    CoordenadaVersiculo coordenada,
    List<VersiculoReacaoModel> servidor, {
    required int inicio,
    int? apenasVersId,
  }) async {
    final db = await _banco.db;
    final porVersiculo = {for (final r in servidor) r.versId: r};
    await db.transaction((txn) async {
      final locais = apenasVersId == null
          ? (await txn.query(
              'reacao',
              where: 'usua_id = ? AND versa_id = ? AND livr_id = ? AND capi_numero = ?',
              whereArgs: [usuaId, coordenada.versaId, coordenada.livrId, coordenada.capiNumero],
            )).map(ReacaoLocal._fromRow).toList()
          : [?await _reacao(txn, usuaId, apenasVersId)];
      final sincronizadasDepois = <int>{
        for (final row in await txn.query(
          'reacao',
          columns: ['vers_id'],
          where: 'usua_id = ? AND sincronizado_em > ?',
          whereArgs: [usuaId, inicio],
        ))
          row['vers_id']! as int,
      };
      final vistos = <int>{};

      for (final local in locais) {
        vistos.add(local.versId);
        if (sincronizadasDepois.contains(local.versId)) continue;
        final remoto = porVersiculo[local.versId];
        if (local.pendente) {
          await txn.update(
            'reacao',
            {
              'vrea_id': remoto?.vreaId,
              'lido_servidor': _bool(remoto?.vreaLido ?? false),
              if (!local.comentarioAlterado) 'comentario': remoto?.vreaComentario,
            },
            where: 'usua_id = ? AND vers_id = ?',
            whereArgs: [usuaId, local.versId],
          );
        } else if (remoto == null) {
          await txn.delete('reacao', where: 'usua_id = ? AND vers_id = ?', whereArgs: [usuaId, local.versId]);
        } else {
          await txn.update(
            'reacao',
            {
              'vrea_id': remoto.vreaId,
              'lido': _bool(remoto.vreaLido),
              'lido_servidor': _bool(remoto.vreaLido),
              'comentario': remoto.vreaComentario,
            },
            where: 'usua_id = ? AND vers_id = ?',
            whereArgs: [usuaId, local.versId],
          );
        }
      }

      for (final remoto in servidor) {
        if (vistos.contains(remoto.versId) || sincronizadasDepois.contains(remoto.versId)) continue;
        if (apenasVersId != null && remoto.versId != apenasVersId) continue;
        await txn.insert('reacao', {
          'usua_id': usuaId,
          'vers_id': remoto.versId,
          'versa_id': coordenada.versaId,
          'livr_id': coordenada.livrId,
          'capi_numero': coordenada.capiNumero,
          'vrea_id': remoto.vreaId,
          'lido': _bool(remoto.vreaLido),
          'lido_servidor': _bool(remoto.vreaLido),
          'comentario': remoto.vreaComentario,
        });
      }
    });
  }

  /// Reações alteradas no aparelho e ainda não enviadas; com [versaId], só as da versão.
  Future<List<ReacaoLocal>> reacoesPendentes(int usuaId, {int? versaId}) async {
    final db = await _banco.db;
    final rows = await db.query(
      'reacao',
      where: 'usua_id = ? AND pendente = 1${versaId == null ? '' : ' AND versa_id = ?'}',
      whereArgs: [usuaId, ?versaId],
      orderBy: 'versa_id, livr_id, capi_numero, vers_id',
    );
    return rows.map(ReacaoLocal._fromRow).toList(growable: false);
  }

  /// A API recebeu a marcação [lidoEnviado] do versículo. Guarda o que ela tem agora e, se a linha não mudou desde
  /// a leitura ([versao]), tira a pendência.
  Future<void> concluirReacao(
    int usuaId,
    int versId, {
    required int versao,
    required int? vreaId,
    required bool lidoEnviado,
    String? comentario,
  }) async {
    final db = await _banco.db;
    await db.transaction((txn) async {
      await txn.update(
        'reacao',
        {'vrea_id': vreaId, 'lido_servidor': _bool(lidoEnviado), 'sincronizado_em': _agoraMs},
        where: 'usua_id = ? AND vers_id = ?',
        whereArgs: [usuaId, versId],
      );
      await txn.update(
        'reacao',
        {'pendente': 0, 'comentario_alterado': 0, 'tentativas': 0, 'comentario': comentario},
        where: 'usua_id = ? AND vers_id = ? AND versao = ?',
        whereArgs: [usuaId, versId, versao],
      );
    });
  }

  /// A API recusou a marcação: volta ao último estado conhecido na API e tira a pendência.
  Future<void> descartarReacao(int usuaId, int versId, {required int versao}) async {
    final db = await _banco.db;
    await db.rawUpdate(
      'UPDATE reacao SET lido = lido_servidor, pendente = 0, comentario_alterado = 0, tentativas = 0 '
      'WHERE usua_id = ? AND vers_id = ? AND versao = ?',
      [usuaId, versId, versao],
    );
  }

  /// Conta mais uma falha da API ao enviar a reação e devolve o total.
  Future<int> registrarFalhaReacao(int usuaId, int versId) => _registrarFalha('reacao', usuaId, versId);

  // ---------------------------------------------------------------------------------------------------------------
  // Indicações

  /// Indicações do usuário no capítulo, inclusive as removidas no aparelho e ainda não sincronizadas.
  Future<List<IndicacaoLocal>> indicacoesDoCapitulo(int usuaId, int versaId, int livrId, int capiNumero) async {
    final db = await _banco.db;
    final rows = await db.query(
      'indicacao',
      where: 'usua_id = ? AND versa_id = ? AND livr_id = ? AND capi_numero = ?',
      whereArgs: [usuaId, versaId, livrId, capiNumero],
      orderBy: 'vers_id',
    );
    return rows.map(IndicacaoLocal._fromRow).toList(growable: false);
  }

  Future<IndicacaoLocal?> indicacao(int usuaId, int versId) => _indicacao(null, usuaId, versId);

  Future<IndicacaoLocal?> _indicacao(DatabaseExecutor? executor, int usuaId, int versId) async {
    final db = executor ?? await _banco.db;
    final rows = await db.query('indicacao', where: 'usua_id = ? AND vers_id = ?', whereArgs: [usuaId, versId]);
    return rows.isEmpty ? null : IndicacaoLocal._fromRow(rows.first);
  }

  Future<IndicacaoLocal?> indicacaoPorVindId(int usuaId, int vindId) async {
    final db = await _banco.db;
    final rows = await db.query('indicacao', where: 'usua_id = ? AND vind_id = ?', whereArgs: [usuaId, vindId]);
    return rows.isEmpty ? null : IndicacaoLocal._fromRow(rows.first);
  }

  /// Grava no aparelho, como pendente, a indicação do versículo com [comentario] ou, com [excluida], a remoção.
  Future<IndicacaoLocal> gravarIndicacao(
    int usuaId,
    int versId,
    CoordenadaVersiculo c, {
    String? comentario,
    bool excluida = false,
  }) async {
    final db = await _banco.db;
    return db.transaction((txn) async {
      final agora = _agoraMs;
      final atualizadas = await txn.rawUpdate(
        'UPDATE indicacao SET comentario = CASE WHEN ? = 1 THEN comentario ELSE ? END, excluida = ?, pendente = 1, '
        'versao = versao + 1, tentativas = 0, alterado_em = ? WHERE usua_id = ? AND vers_id = ?',
        [_bool(excluida), comentario, _bool(excluida), agora, usuaId, versId],
      );
      if (atualizadas == 0) {
        await txn.insert('indicacao', {
          'usua_id': usuaId,
          'vers_id': versId,
          'versa_id': c.versaId,
          'livr_id': c.livrId,
          'capi_numero': c.capiNumero,
          'comentario': comentario,
          'excluida': _bool(excluida),
          'pendente': 1,
          'versao': 1,
          'alterado_em': agora,
        });
      }
      return (await _indicacao(txn, usuaId, versId))!;
    });
  }

  /// Junta ao aparelho as indicações do usuário devolvidas pela API (só as dele, uma por versículo) para o capítulo
  /// [coordenada]. Mesmas regras de [mesclarReacoesServidor]: linhas pendentes só recebem o `vind_id`.
  Future<void> mesclarIndicacoesServidor(
    int usuaId,
    CoordenadaVersiculo coordenada,
    List<VersiculoIndicacaoModel> minhas, {
    required int inicio,
    int? apenasVersId,
  }) async {
    final db = await _banco.db;
    final porVersiculo = {for (final i in minhas) i.versId: i};
    await db.transaction((txn) async {
      final locais = apenasVersId == null
          ? (await txn.query(
              'indicacao',
              where: 'usua_id = ? AND versa_id = ? AND livr_id = ? AND capi_numero = ?',
              whereArgs: [usuaId, coordenada.versaId, coordenada.livrId, coordenada.capiNumero],
            )).map(IndicacaoLocal._fromRow).toList()
          : [?await _indicacao(txn, usuaId, apenasVersId)];
      final sincronizadasDepois = <int>{
        for (final row in await txn.query(
          'indicacao',
          columns: ['vers_id'],
          where: 'usua_id = ? AND sincronizado_em > ?',
          whereArgs: [usuaId, inicio],
        ))
          row['vers_id']! as int,
      };
      final vistos = <int>{};

      for (final local in locais) {
        vistos.add(local.versId);
        if (sincronizadasDepois.contains(local.versId)) continue;
        final remota = porVersiculo[local.versId];
        if (local.pendente) {
          await txn.update(
            'indicacao',
            {'vind_id': remota?.vindId},
            where: 'usua_id = ? AND vers_id = ?',
            whereArgs: [usuaId, local.versId],
          );
        } else if (remota == null) {
          await txn.delete('indicacao', where: 'usua_id = ? AND vers_id = ?', whereArgs: [usuaId, local.versId]);
        } else {
          await txn.update(
            'indicacao',
            {'vind_id': remota.vindId, 'comentario': remota.vindComentario, 'excluida': 0},
            where: 'usua_id = ? AND vers_id = ?',
            whereArgs: [usuaId, local.versId],
          );
        }
      }

      for (final remota in minhas) {
        if (vistos.contains(remota.versId) || sincronizadasDepois.contains(remota.versId)) continue;
        if (apenasVersId != null && remota.versId != apenasVersId) continue;
        await txn.insert('indicacao', {
          'usua_id': usuaId,
          'vers_id': remota.versId,
          'versa_id': coordenada.versaId,
          'livr_id': coordenada.livrId,
          'capi_numero': coordenada.capiNumero,
          'vind_id': remota.vindId,
          'comentario': remota.vindComentario,
        });
      }
    });
  }

  Future<List<IndicacaoLocal>> indicacoesPendentes(int usuaId) async {
    final db = await _banco.db;
    final rows = await db.query(
      'indicacao',
      where: 'usua_id = ? AND pendente = 1',
      whereArgs: [usuaId],
      orderBy: 'vers_id',
    );
    return rows.map(IndicacaoLocal._fromRow).toList(growable: false);
  }

  /// A API recebeu a indicação (ou a remoção, com [removida]). Guarda o [vindId] e, se a linha não mudou desde a
  /// leitura ([versao]), tira a pendência (a removida é apagada).
  Future<void> concluirIndicacao(
    int usuaId,
    int versId, {
    required int versao,
    required int? vindId,
    bool removida = false,
  }) async {
    final db = await _banco.db;
    await db.transaction((txn) async {
      await txn.update(
        'indicacao',
        {'vind_id': removida ? null : vindId, 'sincronizado_em': _agoraMs},
        where: 'usua_id = ? AND vers_id = ?',
        whereArgs: [usuaId, versId],
      );
      if (removida) {
        await txn.delete(
          'indicacao',
          where: 'usua_id = ? AND vers_id = ? AND versao = ?',
          whereArgs: [usuaId, versId, versao],
        );
      } else {
        await txn.update(
          'indicacao',
          {'pendente': 0, 'tentativas': 0},
          where: 'usua_id = ? AND vers_id = ? AND versao = ?',
          whereArgs: [usuaId, versId, versao],
        );
      }
    });
  }

  /// A API recusou a indicação: apaga a linha (a próxima consulta à API traz o estado de lá).
  Future<void> descartarIndicacao(int usuaId, int versId, {required int versao}) async {
    final db = await _banco.db;
    await db.delete(
      'indicacao',
      where: 'usua_id = ? AND vers_id = ? AND versao = ?',
      whereArgs: [usuaId, versId, versao],
    );
  }

  Future<int> registrarFalhaIndicacao(int usuaId, int versId) => _registrarFalha('indicacao', usuaId, versId);

  // ---------------------------------------------------------------------------------------------------------------
  // Geral

  Future<int> _registrarFalha(String tabela, int usuaId, int versId) async {
    final db = await _banco.db;
    return db.transaction((txn) async {
      await txn.rawUpdate('UPDATE $tabela SET tentativas = tentativas + 1 WHERE usua_id = ? AND vers_id = ?', [
        usuaId,
        versId,
      ]);
      final rows = await txn.query(
        tabela,
        columns: ['tentativas'],
        where: 'usua_id = ? AND vers_id = ?',
        whereArgs: [usuaId, versId],
      );
      return rows.isEmpty ? 0 : rows.first['tentativas']! as int;
    });
  }

  /// Marcações do usuário que ainda não chegaram à API (lidos e indicações).
  Future<int> contarPendentes(int usuaId) async {
    final db = await _banco.db;
    final rows = await db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM reacao WHERE usua_id = ? AND pendente = 1) + '
      '(SELECT COUNT(*) FROM indicacao WHERE usua_id = ? AND pendente = 1) AS total',
      [usuaId, usuaId],
    );
    return rows.first['total'] as int? ?? 0;
  }

  /// Apaga do aparelho os dados do usuário já sincronizados (cache e marcações). As pendentes ficam, para serem
  /// enviadas quando ele entrar de novo.
  Future<void> limparUsuario(int usuaId) async {
    final db = await _banco.db;
    await db.transaction((txn) async {
      await txn.delete('reacao', where: 'usua_id = ? AND pendente = 0', whereArgs: [usuaId]);
      await txn.delete('indicacao', where: 'usua_id = ? AND pendente = 0', whereArgs: [usuaId]);
      await txn.delete('cache', where: 'chave LIKE ?', whereArgs: ['${prefixoUsuario(usuaId)}%']);
    });
  }
}
