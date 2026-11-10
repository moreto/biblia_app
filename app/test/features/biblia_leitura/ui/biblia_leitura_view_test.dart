import 'package:app/config/versao_preferencia.dart';
import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/biblia/indice_capitulo_model.dart';
import 'package:app/data/model/biblia/livro_model.dart';
import 'package:app/data/model/biblia/testamento_model.dart';
import 'package:app/data/model/biblia/versao_model.dart';
import 'package:app/data/model/biblia/versiculo_indicacao_model.dart';
import 'package:app/data/model/biblia/versiculo_indicacao_usuario_model.dart';
import 'package:app/data/model/biblia/versiculo_texto_model.dart';
import 'package:app/data/model/usuario/usuario_resumo_model.dart';
import 'package:app/data/model/versiculo/versiculo_reacao_model.dart';
import 'package:app/features/biblia/biblia_leitura/repository/biblia_leitura_repository.dart';
import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_view.dart';
import 'package:app/features/biblia/biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/capitulo_chip.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/versiculo_indicacao_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_usuario_repository.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usuario_usecase.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _usuario = 7;

const _arc = VersaoModel(versaId: 1, versaCodigo: 'ARC', versaNome: 'Almeida Revista e Corrigida');
const _nvi = VersaoModel(versaId: 2, versaCodigo: 'NVI', versaNome: 'Nova Versão Internacional');

const _genesis = LivroModel(livrId: 1, testId: 1, livrNome: 'Gênesis', livrAbrev: 'Gn', livrCapituloCount: 2);
const _joao = LivroModel(livrId: 43, testId: 2, livrNome: 'João', livrAbrev: 'Jo', livrCapituloCount: 1);

IndiceCapituloModel _cap(LivroModel livro, int numero, int total) => IndiceCapituloModel(
  testId: livro.testId,
  livrId: livro.livrId,
  livrNome: livro.livrNome,
  capiNumero: numero,
  versTotal: total,
);

/// Bíblia em memória: Gênesis 1 (3 versículos), Gênesis 2 (2), Gênesis 3 sem versículos na versão e João 1 (2).
/// Os capítulos lidos ficam em [lidosPorVersao]; as reações por versículo, em [reacoes]. [marcarCapitulo] grava nas
/// reações como a API. O `versId` é `livrId * 1000 + capiNumero * 100 + número`.
class _FakeBibliaLeituraRepository implements BibliaLeituraRepository {
  _FakeBibliaLeituraRepository({Map<int, List<CapituloLidoModel>>? lidos}) : lidosPorVersao = lidos ?? {};

  final Map<int, List<CapituloLidoModel>> lidosPorVersao;
  final marcacoes = <({int versaId, int livrId, int capiNumero, bool lido})>[];
  Exception? erroVersoes;
  Exception? erroMarcar;
  final reacoes = <VersiculoReacaoModel>[];

  final _indice = [_cap(_genesis, 1, 3), _cap(_genesis, 2, 2), _cap(_genesis, 3, 0), _cap(_joao, 1, 2)];

  @override
  Future<Result<List<VersaoModel>>> versoes() async =>
      erroVersoes == null ? const Result.ok([_arc, _nvi]) : Result.error(erroVersoes!);

  @override
  Future<Result<List<TestamentoModel>>> testamentos() async => const Result.ok([
    TestamentoModel(testId: 1, testNome: 'Antigo Testamento'),
    TestamentoModel(testId: 2, testNome: 'Novo Testamento'),
  ]);

  @override
  Future<Result<List<LivroModel>>> livros() async => const Result.ok([_genesis, _joao]);

  @override
  Future<Result<List<IndiceCapituloModel>>> indice(int versaId) async =>
      Result.ok(versaId == _nvi.versaId ? _indice.where((c) => c.livrId == _joao.livrId).toList() : _indice);

  @override
  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, int livrId, int capiNumero) async {
    final total = _indice.firstWhere((c) => c.livrId == livrId && c.capiNumero == capiNumero).versTotal;
    final livro = livrId == _genesis.livrId ? _genesis : _joao;
    return Result.ok([
      for (var n = 1; n <= total; n++)
        VersiculoTextoModel(
          versId: livrId * 1000 + capiNumero * 100 + n,
          versNumero: n,
          versTexto: '${livro.livrNome} $capiNumero texto $n',
          livrId: livrId,
          livrNome: livro.livrNome,
          capiNumero: capiNumero,
        ),
    ]);
  }

  @override
  Future<Result<List<CapituloLidoModel>>> lidos(int versaId) async => Result.ok(lidosPorVersao[versaId] ?? const []);

  @override
  Future<Result<int>> marcarCapitulo(int versaId, int livrId, int capiNumero, {required bool lido}) async {
    if (erroMarcar case final erro?) return Result.error(erro);
    marcacoes.add((versaId: versaId, livrId: livrId, capiNumero: capiNumero, lido: lido));
    final total = _indice.firstWhere((c) => c.livrId == livrId && c.capiNumero == capiNumero).versTotal;
    for (var n = 1; n <= total; n++) {
      final versId = livrId * 1000 + capiNumero * 100 + n;
      final i = reacoes.indexWhere((r) => r.versId == versId);
      if (i >= 0) {
        reacoes[i] = reacoes[i].copyWith(vreaLido: lido);
      } else if (lido) {
        reacoes.add(
          VersiculoReacaoModel(vreaId: 900 + reacoes.length, versId: versId, usuaId: _usuario, vreaLido: true),
        );
      }
    }
    return Result.ok(total);
  }

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoesCapitulo(int versaId, int livrId, int capiNumero) async =>
      Result.ok(reacoes.where((r) => r.versId ~/ 1000 == livrId && (r.versId % 1000) ~/ 100 == capiNumero).toList());
}

/// Reações gravadas nas mesmas [_FakeBibliaLeituraRepository.reacoes] da leitura.
class _FakeVersiculoReacaoRepository implements VersiculoReacaoRepository {
  _FakeVersiculoReacaoRepository(this.leitura);

  final _FakeBibliaLeituraRepository leitura;

  @override
  Future<Result<List<VersiculoReacaoModel>>> reacoes(int versId) async =>
      Result.ok(leitura.reacoes.where((r) => r.versId == versId).toList());

  @override
  Future<Result<VersiculoReacaoModel>> incluir(VersiculoReacaoModel reacao) async {
    final gravada = VersiculoReacaoModel(
      vreaId: 500 + leitura.reacoes.length,
      versId: reacao.versId,
      usuaId: _usuario,
      vreaComentario: reacao.vreaComentario,
      vreaLido: reacao.vreaLido,
    );
    leitura.reacoes.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<VersiculoReacaoModel>> alterar(VersiculoReacaoModel reacao) async {
    leitura.reacoes
      ..removeWhere((r) => r.vreaId == reacao.vreaId)
      ..add(reacao);
    return Result.ok(reacao);
  }
}

/// Indicações em memória; as do [_usuario] são as do usuário logado.
class _FakeVersiculoIndicacaoRepository implements VersiculoIndicacaoRepository {
  _FakeVersiculoIndicacaoRepository([List<VersiculoIndicacaoModel>? iniciais]) : registros = [...?iniciais];

  final List<VersiculoIndicacaoModel> registros;
  final excluidos = <int>[];

  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoes(int versId) async =>
      Result.ok(registros.where((r) => r.versId == versId).toList());

  /// Os `versId` de teste seguem `livro`, `capítulo` e `versículo` com 2 dígitos (ex.: 43101 = João 1:1).
  @override
  Future<Result<List<VersiculoIndicacaoModel>>> indicacoesCapitulo(int versaId, int livrId, int capiNumero) async =>
      Result.ok(registros.where((r) => r.usuaId == _usuario && r.versId ~/ 100 == livrId * 10 + capiNumero).toList());

  @override
  Future<Result<VersiculoIndicacaoModel>> incluir(VersiculoIndicacaoModel indicacao) async {
    final gravada = VersiculoIndicacaoModel(
      vindId: 100 + registros.length,
      versId: indicacao.versId,
      usuaId: _usuario,
      vindComentario: indicacao.vindComentario,
    );
    registros.add(gravada);
    return Result.ok(gravada);
  }

  @override
  Future<Result<VersiculoIndicacaoModel>> alterar(VersiculoIndicacaoModel indicacao) async {
    registros
      ..removeWhere((r) => r.vindId == indicacao.vindId)
      ..add(indicacao);
    return Result.ok(indicacao);
  }

  @override
  Future<Result<void>> excluir(int vindId) async {
    excluidos.add(vindId);
    registros.removeWhere((r) => r.vindId == vindId);
    return const Result.ok(null);
  }
}

/// Destinatários das indicações e usuários cadastrados em memória. [buscas] guarda os textos enviados à busca.
class _FakeVersiculoIndicacaoUsuarioRepository implements VersiculoIndicacaoUsuarioRepository {
  final registros = <VersiculoIndicacaoUsuarioModel>[];
  final buscas = <String>[];
  final cadastrados = const [
    UsuarioResumoModel(usuaId: 21, udetNome: 'Maria da Silva', udetUsuario: 'maria'),
    UsuarioResumoModel(usuaId: 22, udetNome: 'Mariana Souza', udetUsuario: 'mari'),
    UsuarioResumoModel(usuaId: 23, udetUsuario: 'pedro'),
  ];
  int _proximoId = 100;

  @override
  Future<Result<List<VersiculoIndicacaoUsuarioModel>>> usuarios(int vindId) async =>
      Result.ok(registros.where((r) => r.vindId == vindId).toList());

  @override
  Future<Result<VersiculoIndicacaoUsuarioModel>> incluir({required int vindId, required int usuaId}) async {
    final registro = VersiculoIndicacaoUsuarioModel(viusId: _proximoId++, vindId: vindId, usuaId: usuaId);
    registros.add(registro);
    return Result.ok(registro);
  }

  @override
  Future<Result<VersiculoIndicacaoUsuarioModel>> alterar({
    required int viusId,
    required int vindId,
    required int usuaId,
  }) async => Result.ok(VersiculoIndicacaoUsuarioModel(viusId: viusId, vindId: vindId, usuaId: usuaId));

  @override
  Future<Result<void>> excluir(int viusId) async {
    registros.removeWhere((r) => r.viusId == viusId);
    return const Result.ok(null);
  }

  @override
  Future<Result<List<UsuarioResumoModel>>> buscarUsuarios(String texto) async {
    buscas.add(texto);
    final termo = texto.toLowerCase();
    return Result.ok(
      cadastrados.where((u) => '${u.udetNome ?? ''} ${u.udetUsuario ?? ''}'.toLowerCase().contains(termo)).toList(),
    );
  }
}

/// Preferência de versão em memória (no app é o `AppConfig`, em secure storage).
class _FakeVersaoPreferencia implements VersaoPreferencia {
  _FakeVersaoPreferencia();

  @override
  int? versaoId;

  @override
  void setVersaoId(int versaId) => versaoId = versaId;
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale: locale, translations: const []));

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

CapituloLidoModel _lido(LivroModel livro, int capitulo, int lidos, int total, [DateTime? em]) => CapituloLidoModel(
  livrId: livro.livrId,
  livrNome: livro.livrNome,
  livrAbrev: livro.livrAbrev,
  capiNumero: capitulo,
  versTotal: total,
  versLidos: lidos,
  lidoEm: em,
);

void main() {
  late _FakeBibliaLeituraRepository repository;
  late _FakeVersiculoIndicacaoRepository indicacoes;
  late _FakeVersiculoIndicacaoUsuarioRepository indicados;
  late _FakeVersaoPreferencia preferencia;

  setUp(() {
    repository = _FakeBibliaLeituraRepository(
      lidos: {
        _arc.versaId: [
          _lido(_genesis, 1, 3, 3, DateTime(2026, 11, 1)),
          _lido(_genesis, 2, 1, 2, DateTime(2026, 11, 5)),
        ],
      },
    );
    // Gênesis 2: versículo 1 lido (com comentário), como o progresso 1/2 acima.
    repository.reacoes.add(
      const VersiculoReacaoModel(vreaId: 1, versId: 1201, usuaId: _usuario, vreaComentario: 'Amém', vreaLido: true),
    );
    indicacoes = _FakeVersiculoIndicacaoRepository();
    indicados = _FakeVersiculoIndicacaoUsuarioRepository();
    preferencia = _FakeVersaoPreferencia();
  });

  VersiculoReacaoUseCase reacaoUseCase() => VersiculoReacaoUseCase(
    versiculoReacaoRepository: _FakeVersiculoReacaoRepository(repository),
    usuarioLogado: () => _usuario,
  );

  BibliaLeituraUseCase leituraUseCase() =>
      BibliaLeituraUseCase(bibliaLeituraRepository: repository, versaoPreferencia: preferencia);

  VersiculoIndicacaoUseCase indicacaoUseCase() =>
      VersiculoIndicacaoUseCase(versiculoIndicacaoRepository: indicacoes, usuarioLogado: () => _usuario);

  VersiculoIndicacaoUsuarioUseCase indicadoUseCase() =>
      VersiculoIndicacaoUsuarioUseCase(versiculoIndicacaoUsuarioRepository: indicados);

  Future<BibliaLeituraViewmodel> criarViewModel() async {
    final viewModel = BibliaLeituraViewmodel(
      bibliaLeituraUseCase: leituraUseCase(),
      versiculoIndicacaoUseCase: indicacaoUseCase(),
      versiculoReacaoUseCase: reacaoUseCase(),
      versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
    );
    await pumpEventQueue();
    return viewModel;
  }

  group('BibliaLeituraUseCase', () {
    test('lista o Novo Testamento antes do Antigo', () async {
      final testamentos = (await leituraUseCase().testamentos() as Ok<List<TestamentoModel>>).value;
      expect(testamentos.map((t) => t.testNome), ['Novo Testamento', 'Antigo Testamento']);
    });

    test('agrupa o índice por livro e descarta capítulos sem versículos na versão', () async {
      final indice = (await leituraUseCase().indice(_arc.versaId) as Ok<Map<int, List<IndiceCapituloModel>>>).value;
      expect(indice.keys, [_genesis.livrId, _joao.livrId]);
      expect(indice[_genesis.livrId]!.map((c) => c.capiNumero), [1, 2]);
    });

    test('histórico vai do mais recente para o mais antigo, sem data no fim', () {
      final historico = leituraUseCase().historico([
        _lido(_joao, 1, 1, 2),
        _lido(_genesis, 1, 3, 3, DateTime(2026, 11, 1)),
        _lido(_genesis, 2, 1, 2, DateTime(2026, 11, 5)),
      ]);
      expect(historico.map((c) => c.chave), ['1:2', '1:1', '43:1']);
    });

    test('vizinho passa de um livro para o outro e é nulo nas pontas', () async {
      final useCase = leituraUseCase();
      final indice = (await useCase.indice(_arc.versaId) as Ok<Map<int, List<IndiceCapituloModel>>>).value;
      const livros = [_genesis, _joao];
      expect(useCase.vizinho(indice, livros, (livrId: 1, capiNumero: 2), 1), (livrId: 43, capiNumero: 1));
      expect(useCase.vizinho(indice, livros, (livrId: 43, capiNumero: 1), -1), (livrId: 1, capiNumero: 2));
      expect(useCase.vizinho(indice, livros, (livrId: 1, capiNumero: 1), -1), isNull);
      expect(useCase.vizinho(indice, livros, (livrId: 43, capiNumero: 1), 1), isNull);
    });

    test('marca o capítulo não completo e desmarca o completo', () async {
      final useCase = leituraUseCase();
      final marcado = await useCase.alternarCapitulo(1, _cap(_genesis, 2, 2), _genesis, _lido(_genesis, 2, 1, 2));
      expect((marcado as Ok<CapituloLidoModel?>).value?.completo, isTrue);

      final desmarcado = await useCase.alternarCapitulo(1, _cap(_genesis, 1, 3), _genesis, _lido(_genesis, 1, 3, 3));
      expect((desmarcado as Ok<CapituloLidoModel?>).value, isNull);
      expect(repository.marcacoes.map((m) => m.lido), [true, false]);
    });
  });

  group('VersiculoIndicacaoUseCase', () {
    test('conta todas as indicações e separa a mais recente do usuário logado', () async {
      indicacoes.registros.addAll(const [
        VersiculoIndicacaoModel(vindId: 1, versId: 5, usuaId: 3),
        VersiculoIndicacaoModel(vindId: 2, versId: 5, usuaId: _usuario, vindComentario: 'antiga'),
        VersiculoIndicacaoModel(vindId: 4, versId: 5, usuaId: _usuario, vindComentario: 'nova'),
        VersiculoIndicacaoModel(vindId: 6, versId: 9, usuaId: _usuario),
      ]);
      final result = (await indicacaoUseCase().indicacoes(5) as Ok<IndicacoesVersiculo>).value;
      expect(result.total, 3);
      expect(result.minha?.vindComentario, 'nova');
    });

    test('inclui quando o usuário ainda não indicou e altera quando já indicou', () async {
      final useCase = indicacaoUseCase();
      final incluida = (await useCase.indicar(5, null, comentario: '  bom  ') as Ok<VersiculoIndicacaoModel>).value;
      expect(incluida.vindComentario, 'bom');

      final alterada = (await useCase.indicar(5, incluida, comentario: '') as Ok<VersiculoIndicacaoModel>).value;
      expect(alterada.vindId, incluida.vindId);
      expect(alterada.vindComentario, isNull);
      expect(indicacoes.registros, hasLength(1));
    });

    test('comentário acima do limite devolve comentarioMaximo500', () async {
      final result = await indicacaoUseCase().indicar(5, null, comentario: 'x' * 501);
      expect(((result as Error).error as HandledException).message, 'comentarioMaximo500');
      expect(indicacoes.registros, isEmpty);
    });

    test('remove a indicação do usuário', () async {
      final result = await indicacaoUseCase().remover(
        const VersiculoIndicacaoModel(vindId: 8, versId: 5, usuaId: _usuario),
      );
      expect(result, isA<Ok<void>>());
      expect(indicacoes.excluidos, [8]);
    });
  });

  group('VersiculoIndicacaoUsuarioUseCase', () {
    const indicacao = VersiculoIndicacaoModel(vindId: 9, versId: 43101, usuaId: _usuario);
    const maria = UsuarioResumoModel(usuaId: 21, udetNome: 'Maria da Silva', udetUsuario: 'maria');

    test('busca com menos de 2 caracteres não chama a API e esconde quem já foi indicado', () async {
      final uc = indicadoUseCase();
      expect((await uc.buscar(' m ', const [])) as Ok, isA<Ok<List<UsuarioResumoModel>>>());
      expect(indicados.buscas, isEmpty);

      const jaIndicado = VersiculoIndicacaoUsuarioModel(viusId: 1, vindId: 9, usuaId: 21);
      final result = await uc.buscar(' mar ', const [jaIndicado]);
      expect((result as Ok<List<UsuarioResumoModel>>).value.map((u) => u.usuaId), [22]);
      expect(indicados.buscas, ['mar']);
    });

    test('adicionar exige a indicação gravada e não repete o usuário', () async {
      final uc = indicadoUseCase();
      final semIndicacao = await uc.adicionar(null, maria, const []);
      expect(((semIndicacao as Error).error as HandledException).message, 'indiqueAntesDeAdicionarUsuarios');

      final adicionado = await uc.adicionar(indicacao, maria, const []);
      final registro = (adicionado as Ok<VersiculoIndicacaoUsuarioModel>).value;
      expect((registro.vindId, registro.usuaId, registro.udetNome), (9, 21, 'Maria da Silva'));

      final repetido = await uc.adicionar(indicacao, maria, [registro]);
      expect(((repetido as Error).error as HandledException).message, 'usuarioJaIndicado');
      expect(indicados.registros, hasLength(1));
    });

    test('estado da indicação: nenhuma, indicado sem comentário e comentado', () {
      final uc = indicacaoUseCase();
      expect(uc.estado(null), EstadoIndicacao.nenhuma);
      expect(
        uc.estado(const VersiculoIndicacaoModel(vindId: 1, versId: 1, vindComentario: '  ')),
        EstadoIndicacao.indicado,
      );
      expect(
        uc.estado(const VersiculoIndicacaoModel(vindId: 1, versId: 1, vindComentario: 'Lindo')),
        EstadoIndicacao.comentado,
      );
    });

    test('lista vazia sem indicação gravada e nome mostrado cai para o nome de usuário', () async {
      final uc = indicadoUseCase();
      expect(((await uc.usuarios(null)) as Ok<List<VersiculoIndicacaoUsuarioModel>>).value, isEmpty);
      expect(uc.nomeExibicao(udetNome: ' ', udetUsuario: 'pedro'), 'pedro');
      expect(uc.nomeExibicao(udetNome: 'Maria', udetUsuario: 'maria'), 'Maria');
      expect(uc.nomeExibicao(), isNull);
    });
  });

  group('BibliaLeituraViewmodel', () {
    test('carrega versões, livros, índice e progresso da primeira versão', () async {
      final viewModel = await criarViewModel();
      expect(viewModel.carregarCommand.completed, isTrue);
      expect(viewModel.versao?.versaCodigo, 'ARC');
      expect(viewModel.livros.map((l) => l.livrNome), ['Gênesis', 'João']);
      expect(viewModel.capitulosLidosDo(_genesis.livrId), 1);
      expect(viewModel.lidoDe(_genesis.livrId, 2)?.completo, isFalse);
      expect(viewModel.historico.first.capiNumero, 2);
    });

    test('filtra os livros pelo testamento', () async {
      final viewModel = await criarViewModel();
      expect(viewModel.testamentos.map((t) => t.testId), [2, 1]);
      viewModel.selecionarTestamento(2);
      expect(viewModel.livros.map((l) => l.livrNome), ['João']);
      viewModel.selecionarTestamento(null);
      expect(viewModel.livros, hasLength(2));
    });

    test('abre o capítulo, marca como lido e navega para o próximo', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      expect(viewModel.versiculos, hasLength(2));
      expect(viewModel.proximo, (livrId: 43, capiNumero: 1));

      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.lidoAtual?.completo, isTrue);
      expect(viewModel.capitulosLidosDo(_genesis.livrId), 2);
      expect(viewModel.consumirFeedback(), (mensagem: 'capituloMarcadoLido', lido: true));
      expect(viewModel.feedback, isNull);

      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.lidoAtual, isNull);
      expect(repository.marcacoes.map((m) => m.lido), [true, false]);
      expect(viewModel.consumirFeedback(), (mensagem: 'capituloDesmarcadoLido', lido: false));
    });

    test('erro ao marcar mantém o progresso anterior', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      repository.erroMarcar = HandledException(message: 'erroApi');
      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.marcarLidoCommand.error, isTrue);
      expect(viewModel.lidoAtual?.versLidos, 1);
    });

    test('trocar a versão recarrega o índice e fecha o capítulo que a versão não tem', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 1));
      await viewModel.versaoCommand.execute(_nvi);
      expect(viewModel.versao?.versaCodigo, 'NVI');
      expect(viewModel.livros.map((l) => l.livrNome), ['João']);
      expect(viewModel.capitulo, isNull);
      expect(viewModel.historico, isEmpty);
    });

    test('indica e remove a indicação do versículo selecionado', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      await viewModel.indicacoesCommand.execute(viewModel.versiculos!.first);
      expect(viewModel.indicacoes?.total, 0);

      await viewModel.indicarCommand.execute('gostei');
      expect(viewModel.indicacoes?.total, 1);
      expect(viewModel.indicacoes?.minha?.vindComentario, 'gostei');

      await viewModel.removerIndicacaoCommand.execute();
      expect(viewModel.indicacoes?.total, 0);
      expect(viewModel.indicacoes?.minha, isNull);
    });

    test('abre o capítulo com o estado da indicação de cada versículo e atualiza ao indicar e remover', () async {
      indicacoes.registros.add(
        const VersiculoIndicacaoModel(vindId: 1, versId: 43102, usuaId: _usuario, vindComentario: 'Lindo'),
      );
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      expect(viewModel.estadoIndicacao(43101), EstadoIndicacao.nenhuma);
      expect(viewModel.estadoIndicacao(43102), EstadoIndicacao.comentado);

      await viewModel.indicacoesCommand.execute(viewModel.versiculos!.first);
      await viewModel.indicarCommand.execute(null);
      expect(viewModel.estadoIndicacao(43101), EstadoIndicacao.indicado);
      await viewModel.indicarCommand.execute('Amém');
      expect(viewModel.estadoIndicacao(43101), EstadoIndicacao.comentado);

      await viewModel.removerIndicacaoCommand.execute();
      expect(viewModel.estadoIndicacao(43101), EstadoIndicacao.nenhuma);
    });

    test('tocar na linha destaca o versículo e tocar de novo remove; trocar de capítulo limpa', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      viewModel.destacarVersiculo(43101);
      expect(viewModel.versiculoDestacado, 43101);
      viewModel.destacarVersiculo(43102);
      expect(viewModel.versiculoDestacado, 43102);
      viewModel.destacarVersiculo(43102);
      expect(viewModel.versiculoDestacado, isNull);

      viewModel.destacarVersiculo(43101);
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      expect(viewModel.versiculoDestacado, isNull);
    });

    test('busca, adiciona e remove usuários da indicação', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      await viewModel.indicacoesCommand.execute(viewModel.versiculos!.first);
      await viewModel.indicarCommand.execute(null);
      expect(viewModel.indicados, isEmpty);

      await viewModel.buscarUsuarios('mar');
      expect(viewModel.usuariosEncontrados.map((u) => u.usuaId), [21, 22]);

      await viewModel.adicionarIndicadoCommand.execute(viewModel.usuariosEncontrados.first);
      expect(viewModel.indicados.map((i) => (i.usuaId, i.udetNome)), [(21, 'Maria da Silva')]);
      expect(viewModel.usuariosEncontrados.map((u) => u.usuaId), [22]);

      // Reabrir o versículo carrega os destinatários da indicação.
      await viewModel.indicacoesCommand.execute(viewModel.versiculos!.first);
      expect(viewModel.indicados.map((i) => i.usuaId), [21]);

      await viewModel.removerIndicadoCommand.execute(viewModel.indicados.single);
      expect(viewModel.indicados, isEmpty);
      expect(indicados.registros, isEmpty);
    });

    test('abre o capítulo com o estado lido de cada versículo', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      expect(viewModel.versiculoLido(1201), isTrue);
      expect(viewModel.versiculoLido(1202), isFalse);
    });

    test('marcar o versículo atualiza o progresso do capítulo e mantém o comentário', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));

      await viewModel.marcarVersiculoCommand.execute(viewModel.versiculos![1]);
      expect(viewModel.versiculoLido(1202), isTrue);
      expect(viewModel.lidoAtual?.completo, isTrue);
      expect(viewModel.capitulosLidosDo(_genesis.livrId), 2);
      expect(viewModel.consumirFeedback(), (mensagem: 'capituloConcluido', lido: true));

      await viewModel.marcarVersiculoCommand.execute(viewModel.versiculos![0]);
      expect(viewModel.versiculoLido(1201), isFalse);
      expect(viewModel.lidoAtual?.versLidos, 1);
      expect(viewModel.consumirFeedback(), (mensagem: 'versiculoDesmarcadoLido', lido: false));
      expect(repository.reacoes.firstWhere((r) => r.versId == 1201).vreaComentario, 'Amém');

      await viewModel.marcarVersiculoCommand.execute(viewModel.versiculos![0]);
      expect(repository.reacoes.firstWhere((r) => r.versId == 1201).vreaComentario, 'Amém');
      expect(repository.reacoes.where((r) => r.versId == 1201), hasLength(1));
      expect(viewModel.consumirFeedback(), (mensagem: 'capituloConcluido', lido: true));
    });

    test('desmarcar todos os versículos remove o capítulo do progresso', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 1, capiNumero: 2));
      await viewModel.marcarVersiculoCommand.execute(viewModel.versiculos![0]);
      expect(viewModel.lidoAtual, isNull);
    });

    test('progresso do livro conta capítulos começados e avança por versículo lido', () async {
      final viewModel = await criarViewModel();
      // Gênesis: cap. 1 completo (3/3) e cap. 2 começado (1/2) = 4 de 5 versículos.
      final genesis = viewModel.progressoDo(_genesis.livrId);
      expect(genesis.completos, 1);
      expect(genesis.emAndamento, 1);
      expect(genesis.total, 2);
      expect(genesis.fracao, closeTo(4 / 5, 1e-9));

      // Sem capítulo completo, a leitura parcial ainda aparece.
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      await viewModel.marcarVersiculoCommand.execute(viewModel.versiculos!.first);
      final joao = viewModel.progressoDo(_joao.livrId);
      expect(joao.completos, 0);
      expect(joao.emAndamento, 1);
      expect(joao.fracao, closeTo(1 / 2, 1e-9));
    });

    test('marcar o capítulo inteiro marca cada versículo', () async {
      final viewModel = await criarViewModel();
      await viewModel.abrirCapituloCommand.execute((livrId: 43, capiNumero: 1));
      expect(viewModel.versiculoLido(43101), isFalse);

      await viewModel.marcarLidoCommand.execute();
      expect(viewModel.versiculoLido(43101), isTrue);
      expect(viewModel.versiculoLido(43102), isTrue);
    });

    test('abre na versão salva e salva a versão escolhida', () async {
      preferencia.versaoId = _nvi.versaId;
      final viewModel = await criarViewModel();
      expect(viewModel.versao?.versaCodigo, 'NVI');

      await viewModel.versaoCommand.execute(_arc);
      expect(preferencia.versaoId, _arc.versaId);
    });

    test('versão salva que não existe mais abre na primeira', () async {
      preferencia.versaoId = 99;
      final viewModel = await criarViewModel();
      expect(viewModel.versao?.versaCodigo, 'ARC');
      expect(preferencia.versaoId, 99);
    });

    test('falha no carregamento deixa o índice nulo', () async {
      repository.erroVersoes = HandledException(message: 'erroApi');
      final viewModel = await criarViewModel();
      expect(viewModel.carregarCommand.error, isTrue);
      expect(viewModel.indice, isNull);
    });
  });

  group('BibliaLeituraView', () {
    Future<BibliaLeituraViewmodel> montar(WidgetTester tester) async {
      final viewModel = BibliaLeituraViewmodel(
        bibliaLeituraUseCase: leituraUseCase(),
        versiculoIndicacaoUseCase: indicacaoUseCase(),
        versiculoReacaoUseCase: reacaoUseCase(),
        versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
          home: BibliaLeituraView(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('mostra os livros com o progresso e abre o capítulo tocado', (tester) async {
      await montar(tester);
      expect(find.text('leituraBiblica'), findsOneWidget);
      expect(find.text('Gênesis'), findsOneWidget);
      expect(find.text('1/2 capitulosLidos · 1 emAndamento'), findsOneWidget);

      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      expect(find.byType(CapituloChip), findsNWidgets(2));

      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 2'), findsOneWidget);
      expect(find.textContaining('Gênesis 2 texto 1'), findsOneWidget);
      expect(find.text('1/2 versiculosLidos'), findsOneWidget);

      await tester.tap(find.text('marcarCapituloLido'));
      await tester.pumpAndSettle();
      expect(find.text('capituloLido'), findsOneWidget);
      expect(find.text('desmarcarCapituloLido'), findsOneWidget);
      expect(find.text('capituloMarcadoLido'), findsOneWidget);

      await tester.tap(find.text('desmarcarCapituloLido'));
      await tester.pumpAndSettle();
      expect(find.text('capituloDesmarcadoLido'), findsOneWidget);
      expect(find.text('capituloMarcadoLido'), findsNothing);
    });

    testWidgets('a versão é escolhida no índice, acima dos testamentos, e não na AppBar', (tester) async {
      final viewModel = await montar(tester);
      final selecao = find.byType(DropdownButtonFormField<int>);
      expect(selecao, findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: selecao), findsNothing);
      expect(tester.getTopLeft(selecao).dy, lessThan(tester.getTopLeft(find.byType(ChoiceChip).first).dy));

      await tester.tap(selecao);
      await tester.pumpAndSettle();
      await tester.tap(find.text('NVI · Nova Versão Internacional').last);
      await tester.pumpAndSettle();
      expect(viewModel.versao?.versaCodigo, 'NVI');
      expect(find.text('Gênesis'), findsNothing);
      expect(find.text('João'), findsOneWidget);
    });

    testWidgets('o histórico lista o que foi lido e abre o capítulo', (tester) async {
      await montar(tester);
      await tester.tap(find.byTooltip('historicoLeitura'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 2'), findsOneWidget);
      expect(find.text('Gênesis 1'), findsOneWidget);

      await tester.tap(find.text('Gênesis 1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gênesis 1 texto 3'), findsOneWidget);
      expect(find.text('capituloLido'), findsOneWidget);
    });

    testWidgets('tocar o versículo abre a indicação e permite indicar', (tester) async {
      await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('comentarIndicarVersiculo').first);
      await tester.pumpAndSettle();
      expect(find.text('João 1:1'), findsOneWidget);
      expect(find.text('0 indicacoes'), findsOneWidget);

      expect(find.text('indiqueParaAdicionarUsuarios'), findsOneWidget);

      await tester.tap(find.text('indicarVersiculo'));
      await tester.pumpAndSettle();
      expect(find.text('1 indicacoes · voceIndicou'), findsOneWidget);
      expect(find.text('removerIndicacao'), findsOneWidget);
      expect(find.text('nenhumUsuarioIndicado'), findsOneWidget);
    });

    testWidgets('depois de indicar, busca um usuário e o adiciona à indicação', (tester) async {
      await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('comentarIndicarVersiculo').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('indicarVersiculo'));
      await tester.pumpAndSettle();

      final folha = find.descendant(of: find.byType(VersiculoIndicacaoSheet), matching: find.byType(Scrollable)).first;
      final busca = find.widgetWithText(TextField, 'buscarUsuario');
      await tester.scrollUntilVisible(busca, 200, scrollable: folha);
      await tester.enterText(busca, 'ped');
      await tester.pump(VersiculoIndicacaoSheet.esperaBusca);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('@pedro'), 200, scrollable: folha);
      expect(find.text('@pedro'), findsOneWidget);

      await tester.tap(find.byTooltip('adicionarUsuarioIndicado'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(InputChip, 'pedro'), findsOneWidget);
      expect(find.text('@pedro'), findsNothing);
      expect(indicados.registros.single.usuaId, 23);

      await tester.scrollUntilVisible(find.byTooltip('removerUsuarioIndicado'), -200, scrollable: folha);
      await tester.tap(find.byTooltip('removerUsuarioIndicado'));
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsNothing);
      expect(indicados.registros, isEmpty);
    });

    testWidgets('o ícone de cada versículo marca como lido sem abrir a indicação', (tester) async {
      final viewModel = await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('marcarVersiculoLido'), findsNWidgets(2));
      await tester.tap(find.byTooltip('marcarVersiculoLido').first);
      await tester.pumpAndSettle();
      expect(viewModel.versiculoLido(43101), isTrue);
      expect(find.byTooltip('desmarcarVersiculoLido'), findsOneWidget);
      expect(find.text('1/2 versiculosLidos'), findsOneWidget);
      expect(find.byType(VersiculoIndicacaoSheet), findsNothing);
      expect(find.text('versiculoMarcadoLido'), findsOneWidget);
    });

    testWidgets('tocar na linha só destaca o versículo, sem abrir a indicação', (tester) async {
      final viewModel = await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('João 1 texto 1'));
      await tester.pumpAndSettle();
      expect(viewModel.versiculoDestacado, 43101);
      expect(find.byType(VersiculoIndicacaoSheet), findsNothing);
    });

    testWidgets('o ícone da indicação mostra se o versículo tem comentário', (tester) async {
      indicacoes.registros.add(
        const VersiculoIndicacaoModel(vindId: 1, versId: 43102, usuaId: _usuario, vindComentario: 'Lindo'),
      );
      await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('comentarIndicarVersiculo'), findsOneWidget);
      expect(find.byTooltip('versiculoComComentario'), findsOneWidget);
    });

    testWidgets('o ícone abaixo do de lido abre o comentário e a indicação do versículo', (tester) async {
      await montar(tester);
      await tester.tap(find.text('João'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('comentarIndicarVersiculo'), findsNWidgets(2));
      await tester.tap(find.byTooltip('comentarIndicarVersiculo').last);
      await tester.pumpAndSettle();
      expect(find.byType(VersiculoIndicacaoSheet), findsOneWidget);
      expect(find.text('João 1:2'), findsOneWidget);
    });
  });
}
