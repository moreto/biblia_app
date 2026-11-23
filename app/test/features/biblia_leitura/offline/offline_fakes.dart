import 'dart:async';

import 'package:app/data/local/banco_local.dart';
import 'package:app/data/local/conectividade.dart';
import 'package:app/data/local/leitura_local_store.dart';
import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/indice_capitulo_model.dart';
import 'package:app/data/model/biblia/livro_model.dart';
import 'package:app/data/model/biblia/testamento_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/data/model/biblia/versiculo_indicacao_model.dart';
import 'package:app/data/model/biblia/versiculo_texto_model.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/biblia/biblia_leitura/offline/leitura_sincronizacao.dart';
import 'package:app/features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import 'package:commons/commons.dart';
import 'package:service/service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const usuaId = 7;
const versaId = 1;

/// Banco em memória para os testes; feche no tearDown (o banco em memória é compartilhado até ser fechado).
BancoLocal bancoEmMemoria() {
  sqfliteFfiInit();
  return BancoLocal(factory: databaseFactoryFfi, caminho: inMemoryDatabasePath);
}

/// Erro do DioProvider quando a API não responde.
HttpServiceException erroRede() => HttpServiceException(message: 'connectionError');

HttpServiceException erroHttp(int code, [String message = 'dadosInvalidos']) =>
    HttpServiceException(code: code, message: message);

/// Três versículos de João 3 (livro 43), ids 100..102.
List<VersiculoTextoModel> joao3([int quantidade = 3]) => [
  for (var i = 0; i < quantidade; i++)
    VersiculoTextoModel(
      versId: 100 + i,
      versNumero: i + 1,
      versTexto: 'texto ${i + 1}',
      livrId: 43,
      livrNome: 'João',
      capiNumero: 3,
    ),
];

const joao3Coord = (versaId: versaId, livrId: 43, capiNumero: 3);

class FakeConectividade implements Conectividade {
  FakeConectividade({this.online = true});

  @override
  bool online;

  final _controller = StreamController<bool>.broadcast();

  void mudar(bool valor) {
    online = valor;
    _controller.add(valor);
  }

  @override
  Stream<bool> get mudancas => _controller.stream;

  @override
  Future<bool> verificar() async => online;
}

/// API da leitura: cada método devolve o resultado configurado e registra a chamada.
class FakeBibliaApi implements BibliaLeituraRepository {
  final chamadas = <String>[];
  Result<List<VersaoModel>> versoesResult = const Result.ok([
    VersaoModel(versaId: 1, versaCodigo: 'ARC', versaNome: 'Almeida'),
  ]);
  Result<List<CapituloLidoModel>> lidosResult = const Result.ok([]);
  Result<List<VersiculoTextoModel>>? capituloResult;
  Result<List<VersiculoReacaoModel>> reacoesCapituloResult = const Result.ok([]);
  Result<int>? marcarCapituloResult;

  @override
  Future<Result<List<VersaoModel>>> versoes() async {
    chamadas.add('versoes');
    return versoesResult;
  }

  @override
  Future<Result<List<TestamentoModel>>> testamentos() async => const Result.ok([]);

  List<LivroModel> livrosLista = const [
    LivroModel(livrId: 43, testId: 2, livrNome: 'João', livrAbrev: 'Jo', livrCapituloCount: 21),
    LivroModel(livrId: 44, testId: 2, livrNome: 'Atos', livrAbrev: 'At', livrCapituloCount: 28),
  ];
  List<IndiceCapituloModel> indiceLista = const [
    IndiceCapituloModel(testId: 2, livrId: 43, livrNome: 'João', capiNumero: 3, versTotal: 3),
    IndiceCapituloModel(testId: 2, livrId: 44, livrNome: 'Atos', capiNumero: 1, versTotal: 2),
  ];

  @override
  Future<Result<List<LivroModel>>> livros() async => Result.ok(livrosLista);

  @override
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId) async => Result.ok(indiceLista);

  @override
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero) async {
    chamadas.add('capitulo');
    return capituloResult ?? Result.ok(joao3());
  }

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async {
    chamadas.add('lidos');
    return lidosResult;
  }

  @override
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido}) async {
    chamadas.add('marcarCapitulo:$lido');
    return marcarCapituloResult ?? const Result.ok(3);
  }

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoesCapitulo(int versaId, int livrId, int capiNumero) async {
    chamadas.add('reacoesCapitulo');
    return reacoesCapituloResult;
  }
}

class FakeReacaoApi implements VersiculoReacaoRepository {
  final chamadas = <String>[];
  final gravadas = <VersiculoReacaoModel>[];
  Result<List<VersiculoReacaoModel>> reacoesResult = const Result.ok([]);
  Exception? erroGravar;
  var _proximoId = 500;

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId) async {
    chamadas.add('reacoes:$versId');
    return reacoesResult;
  }

  Future<Result<VersiculoReacaoModel>> _gravar(String verbo, VersiculoReacaoModel r) async {
    chamadas.add('$verbo:${r.versId}:${r.vreaLido}');
    final erro = erroGravar;
    if (erro != null) return Result.error(erro);
    final gravada = VersiculoReacaoModel(
      vreaId: r.vreaId ?? _proximoId++,
      versId: r.versId,
      usuaId: usuaId,
      vreaComentario: r.vreaComentario,
      vreaLido: r.vreaLido,
    );
    gravadas.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao) => _gravar('incluir', reacao);

  @override
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao) => _gravar('alterar', reacao);
}

class FakeIndicacaoApi implements VersiculoIndicacaoRepository {
  final chamadas = <String>[];
  Result<List<VersiculoIndicacaoModel>> indicacoesResult = const Result.ok([]);
  Result<List<VersiculoIndicacaoModel>> indicacoesCapituloResult = const Result.ok([]);
  Result<void> excluirResult = const Result.ok(null);
  var _proximoId = 900;

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoes(int versId) async {
    chamadas.add('indicacoes:$versId');
    return indicacoesResult;
  }

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoesCapitulo(int versaId, int livrId, int capiNumero) async {
    chamadas.add('indicacoesCapitulo');
    return indicacoesCapituloResult;
  }

  @override
  Future<Result<VersiculoIndicacaoModel>> incluir(VersiculoIndicacaoModel i) async {
    chamadas.add('incluir:${i.versId}:${i.vindComentario}');
    return Result.ok(
      VersiculoIndicacaoModel(vindId: _proximoId++, versId: i.versId, usuaId: usuaId, vindComentario: i.vindComentario),
    );
  }

  @override
  Future<Result<VersiculoIndicacaoModel>> alterar(VersiculoIndicacaoModel i) async {
    chamadas.add('alterar:${i.vindId}:${i.vindComentario}');
    return Result.ok(i);
  }

  @override
  Future<Result<void>> excluir(int vindId) async {
    chamadas.add('excluir:$vindId');
    return excluirResult;
  }
}

/// Conjunto montado para os testes: banco em memória, conexão, APIs falsas e a sincronização.
class Ambiente {
  Ambiente({bool online = true}) : conectividade = FakeConectividade(online: online) {
    banco = bancoEmMemoria();
    store = LeituraLocalStore(banco);
    sincronizacao = LeituraSincronizacao(
      store: store,
      conectividade: conectividade,
      bibliaRemoto: bibliaApi,
      reacaoRemoto: reacaoApi,
      indicacaoRemoto: indicacaoApi,
      usuarioLogado: () => usuaId,
    );
  }

  late final BancoLocal banco;
  late final LeituraLocalStore store;
  late final LeituraSincronizacao sincronizacao;
  final FakeConectividade conectividade;
  final bibliaApi = FakeBibliaApi();
  final reacaoApi = FakeReacaoApi();
  final indicacaoApi = FakeIndicacaoApi();

  Future<void> fechar() async {
    sincronizacao.dispose();
    await banco.fechar();
  }
}
