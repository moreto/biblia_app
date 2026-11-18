import 'package:app/config/brilho_tela.dart';

import 'dart:async';

import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/narracao_voz.dart';
import 'package:app/config/ultimo_capitulo_preferencia.dart';
import 'package:app/config/versao_preferencia.dart';
import 'package:app/data/model/biblia/capitulo_lido_model.dart';
import 'package:app/data/model/dicionario/dicionario_busca_model.dart';
import 'package:app/data/model/dicionario/dicionario_verbete_model.dart';
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
import 'package:app/features/biblia/biblia_leitura/ui/widgets/opcoes_leitura_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/palavra_dicionario_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/versiculo_indicacao_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_repository.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/repository/versiculo_indicacao_usuario_repository.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'package:app/features/biblia/biblia_leitura/versiculo_indicacao/use_case/versiculo_indicacao_usuario_usecase.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/repository/versiculo_reacao_repository.dart';
import 'package:app/features/dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import 'package:app/features/dicionario/repository/dicionario_repository.dart';
import 'package:app/features/dicionario/use_case/dicionario_usecase.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_curl/paper_curl.dart';

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
class _FakeUltimoCapitulo implements UltimoCapituloPreferencia {
  @override
  UltimoCapitulo? ultimoCapitulo;

  @override
  void setUltimoCapitulo(UltimoCapitulo capitulo) => ultimoCapitulo = capitulo;
}

/// Dicionário com um verbete: "texto" (com remissão para "letra"); as demais palavras não existem.
class _FakeDicionarioRepository implements DicionarioRepository {
  final consultadas = <String>[];

  static const _verbetes = {
    'texto': DicionarioVerbeteModel(
      dverId: 1,
      dverPalavra: 'Texto',
      acepcoes: [
        DicionarioAcepcaoModel(
          daceId: 1,
          daceSeq: 1,
          daceClasse: 'm.',
          daceDefinicao: 'Palavras de um autor.',
          remissoes: [DicionarioRemissaoModel(dremTermo: 'letra', dverId: 2)],
        ),
      ],
    ),
    'letra': DicionarioVerbeteModel(
      dverId: 2,
      dverPalavra: 'Letra',
      acepcoes: [DicionarioAcepcaoModel(daceId: 2, daceSeq: 1, daceDefinicao: 'Sinal gráfico.')],
    ),
  };

  @override
  Future<Result<List<DicionarioBuscaModel>>> buscar(String texto, {required int limite}) async =>
      const Result.ok([DicionarioBuscaModel(dverId: 1, dverPalavra: 'Texto')]);

  @override
  Future<Result<List<DicionarioVerbeteModel>>> palavra(String palavra) async {
    consultadas.add(palavra);
    final verbete = _verbetes[palavra];
    return Result.ok([?verbete]);
  }
}

/// Voz em memória: cada fala fica pendente até [terminarFala] (ou [parar]).
class _FakeNarracaoVoz implements NarracaoVoz {
  final falados = <String>[];
  Completer<void>? _fala;
  bool parou = false;

  /// Vozes do aparelho: uma pt-BR comum, uma pt-BR de alta qualidade, uma pt-PT e uma em inglês.
  static const vozesAparelho = [
    VozNarracao(nome: 'pt-br-comum', locale: 'pt-BR', qualidade: 'normal'),
    VozNarracao(nome: 'pt-br-neural', locale: 'pt-BR', qualidade: 'very high', online: true),
    VozNarracao(nome: 'pt-pt', locale: 'pt-PT', qualidade: 'very high'),
    VozNarracao(nome: 'en-us', locale: 'en-US', qualidade: 'very high'),
  ];

  /// Voz e velocidade da última fala.
  VozNarracao? ultimaVoz;
  double? ultimaVelocidade;

  @override
  Future<List<VozNarracao>> vozes() async => vozesAparelho;

  @override
  Future<void> falar(String texto, {required String idioma, VozNarracao? voz, double velocidade = 0.5}) {
    falados.add(texto);
    ultimaVoz = voz;
    ultimaVelocidade = velocidade;
    return (_fala = Completer<void>()).future;
  }

  void terminarFala() => _fala?.complete();

  @override
  Future<void> parar() async {
    parou = true;
    if (_fala?.isCompleted == false) _fala!.complete();
  }
}

class _FakeLeituraPreferencia implements LeituraPreferencia {
  @override
  double escalaFonte = 1;

  @override
  TemaApp tema = TemaApp.sistema;

  @override
  bool mostrarSetas = true;

  /// Nos testes, não pergunta ao passar a página (no app o padrão é perguntar).
  @override
  MarcarAoPassar marcarAoPassar = MarcarAoPassar.nunca;

  @override
  void setMarcarAoPassar(MarcarAoPassar valor) => marcarAoPassar = valor;

  @override
  String? vozNarracao;

  @override
  void setVozNarracao(String? nome) => vozNarracao = nome;

  @override
  double? velocidadeNarracao;

  @override
  bool narracaoContinua = false;

  @override
  void setNarracaoContinua(bool continua) => narracaoContinua = continua;

  @override
  void setVelocidadeNarracao(double velocidade) => velocidadeNarracao = velocidade;

  @override
  void setMostrarSetas(bool mostrar) => mostrarSetas = mostrar;

  @override
  void setEscalaFonte(double escala) => escalaFonte = escala;

  @override
  void setTema(TemaApp tema) => this.tema = tema;
}

/// Brilho em memória; [definidos] registra cada valor aplicado e [restaurado] se voltou ao do sistema.
class _FakeBrilhoTela implements BrilhoTela {
  _FakeBrilhoTela({this.suportado = true});

  final bool suportado;
  final definidos = <double>[];
  bool restaurado = false;

  @override
  Future<double> atual() async => suportado ? 0.5 : throw UnsupportedError('sem brilho');

  @override
  Future<void> definir(double brilho) async => definidos.add(brilho);

  @override
  Future<void> restaurar() async => restaurado = true;
}

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

  /// Sessão do usuário; os testes sem login trocam para false.
  late bool logado;
  late _FakeUltimoCapitulo ultimo;
  late _FakeLeituraPreferencia leitura;
  late _FakeBrilhoTela brilho;
  late _FakeDicionarioRepository dicionario;
  late _FakeNarracaoVoz voz;

  setUp(() {
    logado = true;
    ultimo = _FakeUltimoCapitulo();
    leitura = _FakeLeituraPreferencia();
    brilho = _FakeBrilhoTela();
    dicionario = _FakeDicionarioRepository();
    voz = _FakeNarracaoVoz();
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

  BibliaLeituraUseCase leituraUseCase() => BibliaLeituraUseCase(
    bibliaLeituraRepository: repository,
    versaoPreferencia: preferencia,
    ultimoCapituloPreferencia: ultimo,
    leituraPreferencia: leitura,
    brilhoTela: brilho,
    dicionarioUseCase: DicionarioUseCase(dicionarioRepository: dicionario),
    narracaoVoz: voz,
    estaLogado: () => logado,
  );

  VersiculoIndicacaoUseCase indicacaoUseCase() =>
      VersiculoIndicacaoUseCase(versiculoIndicacaoRepository: indicacoes, usuarioLogado: () => _usuario);

  VersiculoIndicacaoUsuarioUseCase indicadoUseCase() =>
      VersiculoIndicacaoUsuarioUseCase(versiculoIndicacaoUsuarioRepository: indicados);

  Future<BibliaLeituraViewmodel> criarViewModel({LeituraDestino? destino}) async {
    final viewModel = BibliaLeituraViewmodel(
      bibliaLeituraUseCase: leituraUseCase(),
      versiculoIndicacaoUseCase: indicacaoUseCase(),
      versiculoReacaoUseCase: reacaoUseCase(),
      versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
      destino: destino,
    );
    await pumpEventQueue();
    return viewModel;
  }

  group('BibliaLeituraUseCase.ordenarVozes', () {
    test('só português: pt-BR antes de pt-PT, a de maior qualidade primeiro', () {
      expect(BibliaLeituraUseCase.ordenarVozes(_FakeNarracaoVoz.vozesAparelho).map((v) => v.nome), [
        'pt-br-neural',
        'pt-br-comum',
        'pt-pt',
      ]);
    });
  });

  group('BibliaLeituraUseCase.palavraEm', () {
    test('acha a palavra sob o dedo, com acentos, sem pontuação nem número', () {
      const texto = '3  E disse Adão: Esta é agora osso dos meus ossos, apegar-se-á.';
      expect(BibliaLeituraUseCase.palavraEm(texto, texto.indexOf('Adão') + 1), 'Adão');
      // Logo depois da última letra (antes dos dois-pontos) ainda vale a palavra.
      expect(BibliaLeituraUseCase.palavraEm(texto, texto.indexOf(':')), 'Adão');
      expect(BibliaLeituraUseCase.palavraEm(texto, texto.indexOf('ossos,') + 2), 'ossos');
      expect(BibliaLeituraUseCase.palavraEm(texto, texto.indexOf('se-á')), 'se');
      expect(BibliaLeituraUseCase.palavraEm(texto, 0), isNull);
      expect(BibliaLeituraUseCase.palavraEm(texto, 2), isNull);
    });
  });

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

    test('sequencia: um capítulo por página, na ordem dos livros, sem capítulos vazios', () async {
      final useCase = leituraUseCase();
      final indice = (await useCase.indice(_arc.versaId) as Ok<Map<int, List<IndiceCapituloModel>>>).value;
      expect(useCase.sequencia(indice, [_genesis, _joao]), [
        (livrId: _genesis.livrId, capiNumero: 1),
        (livrId: _genesis.livrId, capiNumero: 2),
        (livrId: _joao.livrId, capiNumero: 1),
      ]);
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

  group('LeituraDestino', () {
    test('vai e volta pela query string', () {
      const destino = LeituraDestino(versaId: 2, livrId: 43, capiNumero: 3, versNumero: 16);
      final lido = LeituraDestino.fromQuery(destino.toQuery())!;
      expect((lido.versaId, lido.livrId, lido.capiNumero, lido.versNumero), (2, 43, 3, 16));
    });

    test('sem livro ou capítulo válidos não há destino', () {
      expect(LeituraDestino.fromQuery(const {}), isNull);
      expect(LeituraDestino.fromQuery(const {'livrId': '43'}), isNull);
      expect(LeituraDestino.fromQuery(const {'livrId': 'x', 'capiNumero': '1'}), isNull);
      expect(LeituraDestino.fromQuery(const {'livrId': '0', 'capiNumero': '1'}), isNull);
    });
  });

  group('BibliaLeituraViewmodel com destino', () {
    test('abre na versão do destino, no capítulo, com o versículo destacado', () async {
      final viewModel = await criarViewModel(
        destino: LeituraDestino(versaId: _nvi.versaId, livrId: _joao.livrId, capiNumero: 1, versNumero: 2),
      );

      expect(viewModel.versao?.versaId, _nvi.versaId);
      expect(viewModel.capitulo, (livrId: _joao.livrId, capiNumero: 1));
      expect(viewModel.versiculoDestacado, 43102);
      expect(viewModel.consumirVersiculoAlvo(), 43102);
      expect(viewModel.consumirVersiculoAlvo(), isNull);
      expect(viewModel.abertaPorDestino, isTrue);
      expect(preferencia.versaoId, isNull, reason: 'abrir pelo destino não troca a versão salva');
    });

    test('versão do destino inexistente usa a versão salva', () async {
      preferencia.versaoId = _arc.versaId;
      final viewModel = await criarViewModel(
        destino: LeituraDestino(versaId: 99, livrId: _genesis.livrId, capiNumero: 2),
      );

      expect(viewModel.versao?.versaId, _arc.versaId);
      expect(viewModel.capitulo, (livrId: _genesis.livrId, capiNumero: 2));
      expect(viewModel.versiculoDestacado, isNull);
    });

    test('capítulo fora do índice da versão fica no índice', () async {
      final viewModel = await criarViewModel(
        destino: LeituraDestino(versaId: _nvi.versaId, livrId: _genesis.livrId, capiNumero: 1, versNumero: 1),
      );

      expect(viewModel.indice, isNotNull);
      expect(viewModel.capitulo, isNull);
    });
  });

  group('BibliaLeituraViewmodel', () {
    test('precarrega o texto da página vizinha sem abrir o capítulo', () async {
      final viewModel = await criarViewModel();
      const vizinha = (livrId: 43, capiNumero: 1);
      expect(viewModel.textoDe(vizinha), isNull);

      await viewModel.precarregar(vizinha);
      expect(viewModel.textoDe(vizinha)!.map((v) => v.versTexto), ['João 1 texto 1', 'João 1 texto 2']);
      expect(viewModel.capitulo, isNull);
    });

    test('guarda o último capítulo aberto, com ou sem login', () async {
      logado = false;
      final viewModel = await criarViewModel();
      expect(ultimo.ultimoCapitulo, isNull);

      await viewModel.abrirCapituloCommand.execute((livrId: _genesis.livrId, capiNumero: 2));
      expect(ultimo.ultimoCapitulo, (versaId: _arc.versaId, livrId: _genesis.livrId, capiNumero: 2));
    });

    test('sem login não carrega progresso, reações nem indicações', () async {
      logado = false;
      final viewModel = await criarViewModel();
      expect(viewModel.indice, isNotNull);
      expect(viewModel.lidoDe(_genesis.livrId, 1), isNull);
      expect(viewModel.historico, isEmpty);

      await viewModel.abrirCapituloCommand.execute((livrId: _genesis.livrId, capiNumero: 2));
      expect(viewModel.versiculos, isNotEmpty);
      expect(viewModel.versiculoLido(1201), isFalse);
    });

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
    testWidgets('como primeira tela (ROTA_INICIAL=continuar), voltar vai para a home', (tester) async {
      final viewModel = BibliaLeituraViewmodel(
        bibliaLeituraUseCase: leituraUseCase(),
        versiculoIndicacaoUseCase: indicacaoUseCase(),
        versiculoReacaoUseCase: reacaoUseCase(),
        versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
        destino: LeituraDestino(versaId: _arc.versaId, livrId: _genesis.livrId, capiNumero: 2),
      );
      final router = GoRouter(
        initialLocation: Routes.bibliaLeitura,
        routes: [
          GoRoute(
            path: Routes.bibliaLeitura,
            builder: (context, state) => BibliaLeituraView(viewModel: viewModel),
          ),
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const Scaffold(body: Text('telaHome')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Gênesis 2 texto 1'), findsOneWidget);

      await tester.tap(find.byTooltip('home'));
      await tester.pumpAndSettle();
      expect(find.text('telaHome'), findsOneWidget);
    });

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

    testWidgets('capítulos em páginas: próximo e anterior viram a página, passando de livro', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();
      expect(find.byType(PageCurlView), findsOneWidget);
      expect(find.text('Gênesis 2'), findsOneWidget);

      await tester.tap(find.byTooltip('proximoCapitulo'));
      await tester.pumpAndSettle();
      expect(find.text('João 1'), findsOneWidget);
      expect(find.textContaining('João 1 texto 1'), findsWidgets);

      await tester.tap(find.byTooltip('capituloAnterior'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 2'), findsOneWidget);
    });

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

      // Marcar o capítulo fica nas opções de leitura (botão central da navegação); o sheet fecha ao marcar.
      await tester.tap(find.byTooltip('opcoesLeitura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('marcarCapituloLido'));
      await tester.pumpAndSettle();
      expect(find.byType(OpcoesLeituraSheet), findsNothing);
      expect(find.text('capituloLido'), findsOneWidget);
      expect(find.text('capituloMarcadoLido'), findsOneWidget);

      await tester.tap(find.byTooltip('opcoesLeitura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('desmarcarCapituloLido'));
      await tester.pumpAndSettle();
      expect(find.text('capituloDesmarcadoLido'), findsOneWidget);
      expect(find.text('capituloMarcadoLido'), findsNothing);
    });

    testWidgets('sem login lê o capítulo sem progresso, histórico, marcações nem indicações', (tester) async {
      logado = false;
      final viewModel = await montar(tester);
      expect(viewModel.logado, isFalse);
      expect(find.text('Gênesis'), findsOneWidget);
      expect(find.textContaining('capitulosLidos'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byTooltip('historicoLeitura'), findsNothing);

      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gênesis 2 texto 1'), findsOneWidget);
      expect(find.textContaining('versiculosLidos'), findsNothing);
      expect(find.text('marcarCapituloLido'), findsNothing);
      expect(find.byTooltip('marcarVersiculoLido'), findsNothing);
      expect(find.byTooltip('desmarcarVersiculoLido'), findsNothing);
      expect(find.byTooltip('comentarIndicarVersiculo'), findsNothing);
      expect(find.byTooltip('versiculoComComentario'), findsNothing);
      // Navegação entre capítulos continua.
      expect(find.byTooltip('proximoCapitulo'), findsOneWidget);

      // As opções de leitura abrem, mas sem marcar o capítulo.
      await tester.tap(find.byTooltip('opcoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.byType(OpcoesLeituraSheet), findsOneWidget);
      expect(find.text('marcarCapituloLido'), findsNothing);
      expect(find.text('tamanhoFonte'), findsOneWidget);
    });

    testWidgets('descer o texto encolhe a AppBar e esconde a navegação até a rolagem parar', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();
      // Tela baixa para o capítulo de teste (3 versículos) ter rolagem.
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      double alturaBarra() => tester.getSize(find.byType(AppBar)).height;
      double opacidadeNavegacao() => tester
          .widget<AnimatedOpacity>(
            // A mais externa é a da rolagem (a interna some o botão durante a virada).
            find.ancestor(of: find.byTooltip('opcoesLeitura'), matching: find.byType(AnimatedOpacity)).last,
          )
          .opacity;
      expect(alturaBarra(), 64);
      expect(opacidadeNavegacao(), 1);

      // Arrasta pelo alto do texto, longe da navegação flutuante (que fica embaixo e capturaria o toque).
      final gesto = await tester.startGesture(tester.getBottomLeft(find.byType(AppBar)) + const Offset(24, 40));
      await gesto.moveBy(const Offset(0, -20));
      await gesto.moveBy(const Offset(0, -40));
      await tester.pump();
      expect(opacidadeNavegacao(), 0);
      await gesto.up();
      await tester.pumpAndSettle();
      expect(alturaBarra(), 44);

      // Parou de rolar: a navegação volta.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(opacidadeNavegacao(), 1);

      // Descer mais esconde a AppBar; fica a alça, que a reabre compacta.
      await tester.dragFrom(tester.getBottomLeft(find.byType(AppBar)) + const Offset(24, 40), const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      await tester.tap(find.byTooltip('mostrarBarra'));
      await tester.pumpAndSettle();
      expect(alturaBarra(), 44);
      await tester.pump(const Duration(seconds: 1));

      // Subir o texto devolve a AppBar ao tamanho normal.
      await tester.dragFrom(tester.getBottomLeft(find.byType(AppBar)) + const Offset(24, 40), const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(alturaBarra(), 64);
      await tester.pump(const Duration(seconds: 1));
    });

    /// Posição (global) dentro da palavra [palavra] do versículo que contém [versiculo].
    Offset posicaoPalavra(WidgetTester tester, String versiculo, String palavra) {
      final paragrafo = tester.renderObject<RenderParagraph>(find.textContaining(versiculo));
      final indice = paragrafo.text.toPlainText().indexOf(palavra) + 2;
      final caret = paragrafo.getOffsetForCaret(TextPosition(offset: indice), Rect.zero);
      return paragrafo.localToGlobal(caret + const Offset(0, 8));
    }

    /// Toque longo na palavra [palavra] do versículo que contém [versiculo].
    Future<void> tocarPalavra(WidgetTester tester, String versiculo, String palavra) async {
      await tester.longPressAt(posicaoPalavra(tester, versiculo, palavra));
      await tester.pumpAndSettle();
    }

    testWidgets('segurar e arrastar seleciona várias palavras, até de outro versículo; abre o trecho', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();

      final gesto = await tester.startGesture(posicaoPalavra(tester, 'Gênesis 2 texto 1', 'texto'));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesto.moveTo(posicaoPalavra(tester, 'Gênesis 2 texto 2', 'Gênesis'));
      await tester.pump();
      await gesto.up();
      await tester.pumpAndSettle();

      expect(find.byType(PalavraDicionarioSheet), findsNothing);
      expect(dicionario.consultadas, isEmpty);
      expect(find.text('Gênesis 2:1-2'), findsOneWidget);
      expect(find.text('texto 1 Gênesis'), findsOneWidget);
      expect(find.text('copiar'), findsOneWidget);

      await tester.tap(find.text('ouvir'));
      await tester.pumpAndSettle();
      expect(voz.falados, ['texto 1 Gênesis']);
    });

    test('trecho e referência da seleção', () {
      const versiculos = [
        VersiculoTextoModel(
          versId: 1,
          versNumero: 1,
          versTexto: 'No princípio criou Deus',
          livrId: 1,
          livrNome: 'Gênesis',
          capiNumero: 1,
        ),
        VersiculoTextoModel(
          versId: 2,
          versNumero: 2,
          versTexto: 'E a terra era sem forma',
          livrId: 1,
          livrNome: 'Gênesis',
          capiNumero: 1,
        ),
      ];
      expect(
        BibliaLeituraUseCase.trecho(versiculos, (indice: 0, offset: 3), (indice: 1, offset: 10)),
        'princípio criou Deus E a terra',
      );
      expect(BibliaLeituraUseCase.referenciaTrecho('Gênesis 1', 1, 2), 'Gênesis 1:1-2');
      expect(BibliaLeituraUseCase.referenciaTrecho('Gênesis 1', 3, 3), 'Gênesis 1:3');
    });

    testWidgets('toque longo numa palavra abre o dicionário dela; a remissão consulta no próprio sheet', (
      tester,
    ) async {
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();

      await tocarPalavra(tester, 'Gênesis 2 texto 1', 'texto');
      expect(find.byType(PalavraDicionarioSheet), findsOneWidget);
      expect(dicionario.consultadas, ['texto']);
      // A palavra tocada fica marcada no texto enquanto o sheet está aberto.
      TextSpan? marcada() {
        final texto = tester.widget<Text>(find.textContaining('Gênesis 2 texto 1').first);
        return (texto.textSpan! as TextSpan).children!.whereType<TextSpan>().where((t) {
          return t.style?.backgroundColor != null;
        }).firstOrNull;
      }

      expect(marcada()?.text, 'texto');
      expect(find.text('Palavras de um autor.'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'letra'));
      await tester.pumpAndSettle();
      expect(dicionario.consultadas.last, 'letra');
      expect(find.text('Sinal gráfico.'), findsOneWidget);

      // Fechar o sheet tira a marcação.
      Navigator.of(tester.element(find.text('Sinal gráfico.'))).pop();
      await tester.pumpAndSettle();
      expect(marcada(), isNull);
    });

    testWidgets('toque longo em palavra que não existe mostra as semelhantes', (tester) async {
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();

      await tocarPalavra(tester, 'Gênesis 2 texto 1', 'Gênesis');
      expect(dicionario.consultadas, ['gênesis']);
      expect(find.text('palavraNaoEncontrada: "gênesis"'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'Texto'));
      await tester.pumpAndSettle();
      expect(find.text('Palavras de um autor.'), findsOneWidget);
    });

    testWidgets('sem login, o toque longo pede para entrar e não consulta o dicionário', (tester) async {
      logado = false;
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();

      await tocarPalavra(tester, 'Gênesis 2 texto 1', 'texto');
      expect(find.text('entreParaConsultarDicionario'), findsOneWidget);
      expect(dicionario.consultadas, isEmpty);
    });

    Future<BibliaLeituraViewmodel> abrirGenesis1(WidgetTester tester) async {
      final viewModel = await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('áudio: narra a partir do versículo destacado, marca o que está lendo e termina sozinho', (
      tester,
    ) async {
      final viewModel = await abrirGenesis1(tester);
      await tester.tap(find.textContaining('Gênesis 1 texto 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.falados, ['Gênesis 1 texto 2']);
      expect(viewModel.versiculoNarrado, 1102);
      expect(find.byTooltip('pararNarracao'), findsOneWidget);

      voz.terminarFala();
      await tester.pumpAndSettle();
      expect(voz.falados.last, 'Gênesis 1 texto 3');
      expect(viewModel.versiculoNarrado, 1103);

      voz.terminarFala();
      await tester.pumpAndSettle();
      expect(viewModel.narrando, isFalse);
      expect(find.byTooltip('ouvirCapitulo'), findsOneWidget);
    });

    testWidgets('áudio: usa a melhor voz em português e a velocidade padrão; a escolhida nas opções vale depois', (
      tester,
    ) async {
      await abrirGenesis1(tester);
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.ultimaVoz?.nome, 'pt-br-neural');
      expect(voz.ultimaVelocidade, BibliaLeituraUseCase.velocidadePadrao);
      await tester.tap(find.byTooltip('pararNarracao'));
      await tester.pumpAndSettle();

      leitura.vozNarracao = 'pt-br-comum';
      leitura.velocidadeNarracao = 0.6;
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.ultimaVoz?.nome, 'pt-br-comum');
      expect(voz.ultimaVelocidade, 0.6);
    });

    testWidgets('áudio contínuo: ao terminar o capítulo, passa a página e continua no próximo', (tester) async {
      leitura.narracaoContinua = true;
      final viewModel = await abrirGenesis1(tester);
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        voz.terminarFala();
        await tester.pumpAndSettle();
      }
      expect(viewModel.capitulo, (livrId: _genesis.livrId, capiNumero: 2));
      expect(voz.falados.last, 'Gênesis 2 texto 1');
      expect(viewModel.narrando, isTrue);

      // Parar cancela a continuação.
      await tester.tap(find.byTooltip('pararNarracao'));
      await tester.pumpAndSettle();
      expect(viewModel.narrando, isFalse);
    });

    testWidgets('áudio: sem destaque começa do primeiro; parar interrompe; trocar de capítulo para', (tester) async {
      final viewModel = await abrirGenesis1(tester);
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.falados, ['Gênesis 1 texto 1']);
      await tester.tap(find.byTooltip('pararNarracao'));
      await tester.pumpAndSettle();
      expect(voz.parou, isTrue);
      expect(viewModel.narrando, isFalse);
      expect(voz.falados, hasLength(1));

      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      voz.parou = false;
      await tester.tap(find.byTooltip('proximoCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.parou, isTrue);
      expect(viewModel.narrando, isFalse);
    });

    Future<void> abrirGenesis2(WidgetTester tester) async {
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();
    }

    testWidgets('ao passar a página (perguntar): pergunta se marca o capítulo anterior; voltar não pergunta', (
      tester,
    ) async {
      leitura.marcarAoPassar = MarcarAoPassar.perguntar;
      await abrirGenesis2(tester);

      await tester.tap(find.byTooltip('proximoCapitulo'));
      await tester.pumpAndSettle();
      expect(find.text('João 1'), findsWidgets);
      expect(find.text('perguntaMarcarCapituloLido'), findsOneWidget);
      expect(find.text('Gênesis 2'), findsOneWidget); // título da pergunta

      await tester.tap(find.text('marcarCapituloLido'));
      await tester.pumpAndSettle();
      expect(repository.marcacoes, [(versaId: _arc.versaId, livrId: _genesis.livrId, capiNumero: 2, lido: true)]);
      expect(find.text('capituloMarcadoLido'), findsOneWidget);

      await tester.tap(find.byTooltip('capituloAnterior'));
      await tester.pumpAndSettle();
      expect(find.text('perguntaMarcarCapituloLido'), findsNothing);
    });

    testWidgets('ao passar a página (perguntar): "agora não" não marca', (tester) async {
      leitura.marcarAoPassar = MarcarAoPassar.perguntar;
      await abrirGenesis2(tester);
      await tester.tap(find.byTooltip('proximoCapitulo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('agoraNao'));
      await tester.pumpAndSettle();
      expect(repository.marcacoes, isEmpty);
    });

    testWidgets('ao passar a página (marcar): marca o anterior sem perguntar', (tester) async {
      leitura.marcarAoPassar = MarcarAoPassar.sempre;
      await abrirGenesis2(tester);
      await tester.tap(find.byTooltip('proximoCapitulo'));
      await tester.pumpAndSettle();
      expect(find.text('perguntaMarcarCapituloLido'), findsNothing);
      expect(repository.marcacoes.single.capiNumero, 2);
    });

    testWidgets('ao passar a página: capítulo já completo ou sem login não pergunta', (tester) async {
      leitura.marcarAoPassar = MarcarAoPassar.perguntar;
      await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1')); // Gênesis 1 já está lido (3/3)
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('proximoCapitulo'));
      await tester.pumpAndSettle();
      expect(find.text('perguntaMarcarCapituloLido'), findsNothing);
    });

    Future<BibliaLeituraViewmodel> abrirOpcoes(WidgetTester tester) async {
      final viewModel = await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('opcoesLeitura'));
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('opções de leitura: escolhe o que fazer ao passar a página', (tester) async {
      await abrirOpcoes(tester);
      expect(find.text('aoPassarPagina'), findsOneWidget);
      await tester.tap(find.text('perguntar'));
      await tester.pumpAndSettle();
      expect(leitura.marcarAoPassar, MarcarAoPassar.perguntar);
    });

    testWidgets('opções de leitura: o tamanho da fonte aumenta o texto e é guardado', (tester) async {
      await abrirOpcoes(tester);
      double tamanhoTexto() {
        final texto = tester.widget<Text>(find.textContaining('Gênesis 2 texto 1').first);
        final spans = (texto.textSpan! as TextSpan).children!;
        return spans.last.style!.fontSize!;
      }

      final antes = tamanhoTexto();
      final slider = find.byKey(const ValueKey('tamanhoFonte'));
      await tester.tapAt(tester.getTopRight(slider) - const Offset(8, -12));
      await tester.pumpAndSettle();
      expect(leitura.escalaFonte, BibliaLeituraUseCase.escalaFonteMaxima);
      expect(tamanhoTexto(), greaterThan(antes));
    });

    testWidgets('opções de leitura: desligar as setas deixa só o botão de opções na navegação', (tester) async {
      await abrirOpcoes(tester);
      expect(find.byTooltip('proximoCapitulo'), findsOneWidget);

      await tester.tap(find.text('mostrarSetasNavegacao'));
      await tester.pumpAndSettle();
      expect(leitura.mostrarSetas, isFalse);
      expect(find.byTooltip('proximoCapitulo'), findsNothing);
      expect(find.byTooltip('capituloAnterior'), findsNothing);
      expect(find.byTooltip('opcoesLeitura'), findsOneWidget);
    });

    testWidgets('opções de leitura: o tema escolhido é guardado', (tester) async {
      await abrirOpcoes(tester);
      expect(find.text('sistema'), findsOneWidget);
      await tester.ensureVisible(find.text('creme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('creme'));
      await tester.pumpAndSettle();
      expect(leitura.tema, TemaApp.creme);

      await tester.ensureVisible(find.text('escuro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('escuro'));
      await tester.pumpAndSettle();
      expect(leitura.tema, TemaApp.escuro);
    });

    testWidgets('opções de leitura: o brilho muda a tela e volta ao do sistema ao sair', (tester) async {
      final viewModel = await abrirOpcoes(tester);
      final slider = find.byKey(const ValueKey('brilho'));
      expect(slider, findsOneWidget);
      expect(viewModel.brilho, 0.5);

      await tester.tapAt(tester.getTopRight(slider) - const Offset(8, -12));
      await tester.pumpAndSettle();
      expect(brilho.definidos.last, greaterThan(0.9));

      viewModel.dispose();
      await tester.pump();
      expect(brilho.restaurado, isTrue);
      // Desmonta a tela antes do fim do teste: o viewmodel já foi descartado.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('opções de leitura: sem suporte a brilho, o ajuste não aparece', (tester) async {
      brilho = _FakeBrilhoTela(suportado: false);
      await abrirOpcoes(tester);
      expect(find.text('tamanhoFonte'), findsOneWidget);
      expect(find.byKey(const ValueKey('brilho')), findsNothing);
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
