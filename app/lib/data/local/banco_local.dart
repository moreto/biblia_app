import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Banco SQLite local do app, usado pela leitura offline da Bíblia.
///
/// Tabelas:
/// - `cache`: respostas da API guardadas como JSON (versões, testamentos, livros, índice, progresso de leitura e
///   indicações de um versículo), para a leitura abrir sem rede;
/// - `versiculo` e `versao_baixada`: texto da Bíblia (capítulos abertos e versões baixadas inteiras);
/// - `reacao` e `indicacao`: marcação de lido e indicação de cada versículo pelo usuário. É o estado que a tela
///   mostra; linhas com `pendente = 1` foram alteradas no aparelho e ainda não chegaram à API (veja
///   `LeituraSincronizacao`).
///
/// [factory] e [caminho] permitem abrir o banco em memória nos testes (`databaseFactoryFfi` e
/// `inMemoryDatabasePath`).
class BancoLocal {
  BancoLocal({this._factory, this._caminho});

  static const versaoBanco = 1;
  static const nomeArquivo = 'biblia_app.db';

  final DatabaseFactory? _factory;
  final String? _caminho;
  Future<Database>? _db;

  /// Abre o banco na primeira chamada; as seguintes reaproveitam a mesma conexão.
  Future<Database> get db => _db ??= _abrir();

  Future<Database> _abrir() async {
    final factory = _factory ?? databaseFactory;
    final caminho = _caminho ?? p.join(await factory.getDatabasesPath(), nomeArquivo);
    return factory.openDatabase(
      caminho,
      options: OpenDatabaseOptions(version: versaoBanco, onCreate: (db, _) => _criar(db)),
    );
  }

  Future<void> fechar() async {
    final aberto = _db;
    _db = null;
    if (aberto != null) await (await aberto).close();
  }

  static Future<void> _criar(Database db) async {
    final batch = db.batch()
      ..execute('CREATE TABLE cache (chave TEXT PRIMARY KEY, valor TEXT NOT NULL, atualizado_em INTEGER NOT NULL)')
      ..execute(
        'CREATE TABLE versiculo (vers_id INTEGER PRIMARY KEY, versa_id INTEGER NOT NULL, livr_id INTEGER NOT NULL, '
        'livr_nome TEXT NOT NULL, capi_numero INTEGER NOT NULL, vers_numero INTEGER NOT NULL, '
        'vers_texto TEXT NOT NULL)',
      )
      ..execute('CREATE INDEX ix_versiculo_capitulo ON versiculo (versa_id, livr_id, capi_numero, vers_numero)')
      ..execute('CREATE TABLE versao_baixada (versa_id INTEGER PRIMARY KEY, baixada_em INTEGER NOT NULL)')
      // lido_servidor: último estado conhecido na API (o progresso offline soma a diferença entre lido e ele).
      // comentario_alterado: o comentário foi mudado no aparelho e deve ser enviado; senão vale o da API.
      // versao: aumenta a cada alteração local; a sincronização só conclui a linha se ela não mudou no meio.
      // tentativas: falhas da API (5xx) ao sincronizar; a alteração é descartada ao chegar no limite.
      ..execute(
        'CREATE TABLE reacao (usua_id INTEGER NOT NULL, vers_id INTEGER NOT NULL, versa_id INTEGER NOT NULL, '
        'livr_id INTEGER NOT NULL, capi_numero INTEGER NOT NULL, vrea_id INTEGER, lido INTEGER NOT NULL, '
        'lido_servidor INTEGER NOT NULL DEFAULT 0, comentario TEXT, comentario_alterado INTEGER NOT NULL DEFAULT 0, '
        'pendente INTEGER NOT NULL DEFAULT 0, versao INTEGER NOT NULL DEFAULT 0, tentativas INTEGER NOT NULL DEFAULT 0, '
        'alterado_em INTEGER NOT NULL DEFAULT 0, sincronizado_em INTEGER NOT NULL DEFAULT 0, '
        'PRIMARY KEY (usua_id, vers_id))',
      )
      ..execute('CREATE INDEX ix_reacao_capitulo ON reacao (usua_id, versa_id, livr_id, capi_numero)')
      ..execute(
        'CREATE TABLE indicacao (usua_id INTEGER NOT NULL, vers_id INTEGER NOT NULL, versa_id INTEGER NOT NULL, '
        'livr_id INTEGER NOT NULL, capi_numero INTEGER NOT NULL, vind_id INTEGER, comentario TEXT, '
        'excluida INTEGER NOT NULL DEFAULT 0, pendente INTEGER NOT NULL DEFAULT 0, versao INTEGER NOT NULL DEFAULT 0, '
        'tentativas INTEGER NOT NULL DEFAULT 0, alterado_em INTEGER NOT NULL DEFAULT 0, '
        'sincronizado_em INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (usua_id, vers_id))',
      )
      ..execute('CREATE INDEX ix_indicacao_capitulo ON indicacao (usua_id, versa_id, livr_id, capi_numero)');
    await batch.commit(noResult: true);
  }
}
