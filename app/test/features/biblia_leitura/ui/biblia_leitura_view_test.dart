import 'package:app/config/anotacao_leitura.dart';
import 'package:app/config/brilho_tela.dart';
import 'package:app/config/compartilhamento.dart';
import 'package:app/config/ditado_sistema.dart';

import 'dart:async';

import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/marca_texto.dart';
import 'package:app/config/narracao_voz.dart';
import 'package:app/config/orientacao_tela.dart';
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
import 'package:app/features/biblia/biblia_leitura/ui/widgets/anotacao_trecho_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/palavra_dicionario_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/tags_leitura_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/tags_trecho.dart';
import 'package:app/features/biblia/biblia_leitura/ui/widgets/versiculo_indicacao_sheet.dart';
import 'package:app/features/biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'package:app/features/biblia/configuracao_leitura/ui/configuracao_leitura_view.dart';
import 'package:app/features/biblia/configuracao_leitura/ui/configuracao_leitura_viewmodel.dart';
import 'package:app/features/biblia/configuracao_leitura/ui/versao_biblia_view.dart';
import 'package:app/features/biblia/configuracao_leitura/ui/voz_narracao_view.dart';
import 'package:app/features/biblia/configuracao_leitura/use_case/configuracao_leitura_usecase.dart';
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
import 'package:components/components.dart' show AppTheme, HighlightColor;
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

/// Marcações em memória, por chave de capítulo.
class _FakeMarcaTexto implements MarcaTextoArmazenamento {
  final salvas = <String, List<MarcaTexto>>{};

  @override
  Future<List<MarcaTexto>> doCapitulo(int versaId, int livrId, int capiNumero) async =>
      salvas['$versaId:$livrId:$capiNumero'] ?? const [];

  @override
  Future<void> salvarCapitulo(int versaId, int livrId, int capiNumero, List<MarcaTexto> marcas) async =>
      salvas['$versaId:$livrId:$capiNumero'] = marcas;
}

/// Anotações e tags em memória.
class _FakeAnotacao implements AnotacaoArmazenamento {
  final salvas = <String, List<AnotacaoTrecho>>{};
  List<TagLeitura> tagsSalvas = const [];

  @override
  Future<List<AnotacaoTrecho>> doCapitulo(int versaId, int livrId, int capiNumero) async =>
      salvas['$versaId:$livrId:$capiNumero'] ?? const [];

  @override
  Future<void> salvarCapitulo(int versaId, int livrId, int capiNumero, List<AnotacaoTrecho> anotacoes) async =>
      salvas['$versaId:$livrId:$capiNumero'] = anotacoes;

  @override
  Future<List<TagLeitura>> tags() async => tagsSalvas;

  @override
  Future<void> salvarTags(List<TagLeitura> tags) async => tagsSalvas = tags;
}

/// Compartilhamento que só guarda os textos.
class _FakeCompartilhamento implements Compartilhamento {
  final compartilhados = <String>[];

  @override
  Future<void> compartilhar(String texto, {String? assunto}) async => compartilhados.add(texto);
}

/// Ditado do sistema que devolve [falado] (nulo = cancelou).
class _FakeDitado implements DitadoSistema {
  String? falado;
  String? idioma;

  @override
  Future<bool> disponivel() async => true;

  @override
  Future<String?> ditar({required String idioma, String? dica}) async {
    this.idioma = idioma;
    return falado;
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
  TemaApp temaLeitura = TemaApp.sistema;

  @override
  double? brilhoLeitura;

  @override
  HighlightColor corMarcaTexto = HighlightColor.amarelo;

  @override
  void setCorMarcaTexto(HighlightColor cor) => corMarcaTexto = cor;

  @override
  void setBrilhoLeitura(double? brilho) => brilhoLeitura = brilho;

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
  void setTemaLeitura(TemaApp tema) => temaLeitura = tema;

  @override
  OrientacaoLeitura orientacao = OrientacaoLeitura.automatica;

  @override
  void setOrientacao(OrientacaoLeitura orientacao) => this.orientacao = orientacao;
}

/// Orientação da tela em memória: [aplicadas] registra cada orientação aplicada.
class _FakeOrientacaoTela implements OrientacaoTela {
  final aplicadas = <OrientacaoLeitura>[];

  @override
  Future<void> aplicar(OrientacaoLeitura orientacao) async => aplicadas.add(orientacao);
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

/// Nas Configurações de leitura, rola até a linha [texto] e a toca (abre o ajuste dela).
Future<void> abrirLinha(WidgetTester tester, String texto) async {
  final linha = find.text(texto);
  await tester.scrollUntilVisible(linha, 100);
  await tester.ensureVisible(linha);
  await tester.pumpAndSettle();
  await tester.tap(linha);
  await tester.pumpAndSettle();
}

/// Fecha o sheet de baixo em que está [dentro].
Future<void> fecharSheet(WidgetTester tester, Finder dentro) async {
  Navigator.of(tester.element(dentro)).pop();
  await tester.pumpAndSettle();
}

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
  late _FakeMarcaTexto marcaTexto;
  late _FakeAnotacao anotacao;
  late _FakeDitado ditado;
  late _FakeOrientacaoTela orientacaoTela;
  late _FakeCompartilhamento compartilhamento;

  setUp(() {
    logado = true;
    ultimo = _FakeUltimoCapitulo();
    leitura = _FakeLeituraPreferencia();
    brilho = _FakeBrilhoTela();
    dicionario = _FakeDicionarioRepository();
    voz = _FakeNarracaoVoz();
    marcaTexto = _FakeMarcaTexto();
    anotacao = _FakeAnotacao();
    ditado = _FakeDitado();
    orientacaoTela = _FakeOrientacaoTela();
    compartilhamento = _FakeCompartilhamento();
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
    marcaTextoArmazenamento: marcaTexto,
    anotacaoArmazenamento: anotacao,
    compartilhamento: compartilhamento,
    orientacaoTela: orientacaoTela,
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
    test('todos os idiomas: pt-BR, depois pt-PT, depois os outros; a de maior qualidade primeiro', () {
      expect(BibliaLeituraUseCase.ordenarVozes(_FakeNarracaoVoz.vozesAparelho).map((v) => v.nome), [
        'pt-br-neural',
        'pt-br-comum',
        'pt-pt',
        'en-us',
      ]);
    });
  });

  group('BibliaLeituraUseCase: idioma, país e nome amigável das vozes', () {
    test('voz listada mas não baixada (notInstalled) fica de fora', () {
      final baixada = VozNarracao.fromMap({'name': 'pt-br-x-afs-local', 'locale': 'pt-BR', 'features': 'embeddedTts'});
      final naoBaixada = VozNarracao.fromMap({
        'name': 'pt-br-x-ptd-local',
        'locale': 'pt-BR',
        'features': 'embeddedTts\tnotInstalled',
      });
      expect(baixada?.instalada, isTrue);
      expect(naoBaixada?.instalada, isFalse);
    });

    final vozes = BibliaLeituraUseCase.ordenarVozes(_FakeNarracaoVoz.vozesAparelho);

    test('voz padrão: a última de pt-BR; sem pt-BR, a primeira', () {
      expect(BibliaLeituraUseCase.vozPadrao(vozes)?.nome, 'pt-br-comum');
      expect(BibliaLeituraUseCase.vozPadrao(vozes.where((v) => !v.locale.startsWith('pt-BR')).toList())?.nome, 'pt-pt');
      expect(BibliaLeituraUseCase.vozPadrao(const []), isNull);
    });

    test('versão padrão: a Bíblia Fácil (pelo nome, sem acento nem maiúsculas); sem ela, a primeira', () {
      const facil = VersaoModel(versaId: 9, versaCodigo: 'BF', versaNome: 'Bíblia Fácil');
      expect(BibliaLeituraUseCase.versaoPadrao(const [_arc, _nvi, facil])?.versaId, 9);
      expect(
        BibliaLeituraUseCase.versaoPadrao(const [
          _arc,
          VersaoModel(versaId: 8, versaCodigo: 'X', versaNome: 'BIBLIA FACIL'),
        ])?.versaId,
        8,
      );
      expect(BibliaLeituraUseCase.versaoPadrao(const [_arc, _nvi])?.versaId, _arc.versaId);
    });

    test('partesLocale separa idioma e país, com - ou _ e sem país', () {
      expect(BibliaLeituraUseCase.partesLocale('pt-BR'), (idioma: 'pt', pais: 'BR'));
      expect(BibliaLeituraUseCase.partesLocale('en_us'), (idioma: 'en', pais: 'US'));
      expect(BibliaLeituraUseCase.partesLocale('es-419'), (idioma: 'es', pais: '419'));
      expect(BibliaLeituraUseCase.partesLocale('zh-Hant-TW'), (idioma: 'zh', pais: 'TW'));
      expect(BibliaLeituraUseCase.partesLocale('fr'), (idioma: 'fr', pais: null));
    });

    test('idiomas, países do idioma e vozes do idioma e país', () {
      expect(BibliaLeituraUseCase.idiomasDasVozes(vozes), ['pt', 'en']);
      expect(BibliaLeituraUseCase.paisesDasVozes(vozes, 'pt'), ['BR', 'PT']);
      expect(BibliaLeituraUseCase.vozesDe(vozes, 'pt', 'BR').map((v) => v.nome), ['pt-br-neural', 'pt-br-comum']);
    });

    test('nome técnico vira "Voz N" (N na ordem do país); nome de gente fica, sem o "(…)"', () {
      expect(BibliaLeituraUseCase.nomeAmigavel(vozes[0], vozes), (nome: null, numero: 1));
      expect(BibliaLeituraUseCase.nomeAmigavel(vozes[1], vozes), (nome: null, numero: 2));
      expect(BibliaLeituraUseCase.nomeAmigavel(vozes[2], vozes), (nome: null, numero: 1));
      const luciana = VozNarracao(nome: 'Luciana (Enhanced)', locale: 'pt-BR', qualidade: 'high');
      expect(BibliaLeituraUseCase.nomeAmigavel(luciana, [luciana]), (nome: 'Luciana', numero: 1));
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

    testWidgets('voltar da leitura devolve o brilho do sistema na hora, mesmo com o viewmodel recriado pela rota', (
      tester,
    ) async {
      leitura.setBrilhoLeitura(0.9);
      BibliaLeituraViewmodel novo() => BibliaLeituraViewmodel(
        bibliaLeituraUseCase: leituraUseCase(),
        versiculoIndicacaoUseCase: indicacaoUseCase(),
        versiculoReacaoUseCase: reacaoUseCase(),
        versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
      );
      // Como no app: o builder da rota cria um viewmodel a cada reconstrução.
      final router = GoRouter(
        initialLocation: Routes.home,
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (context, state) => Scaffold(
              body: TextButton(onPressed: () => context.push(Routes.bibliaLeitura), child: const Text('telaHome')),
            ),
          ),
          GoRoute(
            path: Routes.bibliaLeitura,
            builder: (context, state) => BibliaLeituraView(viewModel: novo()),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.tap(find.text('telaHome'));
      await tester.pumpAndSettle();
      expect(brilho.definidos.last, 0.9);
      router.refresh(); // reconstrói a rota (novo viewmodel)
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pump(); // ainda na animação de saída
      expect(brilho.restaurado, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('telaHome'), findsOneWidget);
    });

    testWidgets('app escuro e leitura creme: cada um no seu tema; na home o brilho volta ao normal', (tester) async {
      leitura
        ..setTemaLeitura(TemaApp.creme)
        ..setBrilhoLeitura(0.9);
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
            path: Routes.configuracoesLeitura,
            builder: (context, state) => ConfiguracaoLeituraView(
              leitura: state.extra! as BibliaLeituraViewmodel,
              viewModel: ConfiguracaoLeituraViewmodel(
                configuracaoLeituraUseCase: ConfiguracaoLeituraUseCase(leituraPreferencia: leitura),
              ),
            ),
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
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.pumpAndSettle();

      // A leitura (e o texto, a AppBar e o fundo dela) fica creme; o brilho da leitura é aplicado.
      final texto = find.textContaining('Gênesis 2 texto 1');
      expect(Theme.of(tester.element(texto)).colorScheme, AppTheme.creme.colorScheme);
      expect(
        tester.widget<Scaffold>(find.ancestor(of: texto, matching: find.byType(Scaffold)).first).backgroundColor ??
            Theme.of(tester.element(texto)).scaffoldBackgroundColor,
        AppTheme.creme.scaffoldBackgroundColor,
      );
      expect(brilho.definidos.last, 0.9);

      // Os sheets abertos da leitura também ficam creme.
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.text('configuracoesLeitura'))).colorScheme, AppTheme.creme.colorScheme);

      // A página de configurações segue o app (escuro).
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(ConfiguracaoLeituraView))).brightness, Brightness.dark);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Na home: tema do app (escuro) e brilho do sistema.
      await tester.tap(find.byTooltip('home'));
      await tester.pumpAndSettle();
      expect(find.text('telaHome'), findsOneWidget);
      expect(Theme.of(tester.element(find.text('telaHome'))).brightness, Brightness.dark);
      expect(brilho.restaurado, isTrue);
    });

    /// A leitura e as Configurações de leitura (que recebem o viewmodel da leitura no `extra`), como no app.
    GoRouter rotas(BibliaLeituraViewmodel viewModel) => GoRouter(
      initialLocation: Routes.bibliaLeitura,
      routes: [
        GoRoute(
          path: Routes.bibliaLeitura,
          builder: (context, state) => BibliaLeituraView(viewModel: viewModel, ditado: ditado),
        ),
        GoRoute(
          path: Routes.configuracoesLeitura,
          builder: (context, state) => ConfiguracaoLeituraView(
            leitura: state.extra! as BibliaLeituraViewmodel,
            viewModel: ConfiguracaoLeituraViewmodel(
              configuracaoLeituraUseCase: ConfiguracaoLeituraUseCase(
                leituraPreferencia: leitura,
                orientacaoTela: orientacaoTela,
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const Scaffold(body: Text('telaLogin')),
        ),
        GoRoute(
          path: Routes.configuracao,
          builder: (context, state) => const Scaffold(body: Text('telaConfiguracaoApp')),
        ),
        GoRoute(
          path: Routes.versaoBiblia,
          builder: (context, state) => VersaoBibliaView(leitura: state.extra! as BibliaLeituraViewmodel),
        ),
        GoRoute(
          path: Routes.vozNarracao,
          builder: (context, state) => VozNarracaoView(leitura: state.extra! as BibliaLeituraViewmodel),
        ),
      ],
    );

    Future<BibliaLeituraViewmodel> montar(WidgetTester tester) async {
      final viewModel = BibliaLeituraViewmodel(
        bibliaLeituraUseCase: leituraUseCase(),
        versiculoIndicacaoUseCase: indicacaoUseCase(),
        versiculoReacaoUseCase: reacaoUseCase(),
        versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: rotas(viewModel),
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.pumpAndSettle();
      return viewModel;
    }

    testWidgets('a engrenagem e as opções abrem as Configurações de leitura; retrato e paisagem valem na leitura', (
      tester,
    ) async {
      final viewModel = await montar(tester);
      // Ao abrir, a leitura aplica a orientação guardada (automática).
      expect(orientacaoTela.aplicadas, [OrientacaoLeitura.automatica]);
      expect(find.byTooltip('telaHorizontal'), findsNothing);

      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfiguracaoLeituraView), findsOneWidget);
      // A linha mostra o valor atual; tocar abre a lista no sheet de baixo.
      expect(find.text('orientacaoAutomatica'), findsOneWidget);
      await abrirLinha(tester, 'orientacaoTela');
      await tester.tap(find.text('paisagem'));
      await tester.pumpAndSettle();
      expect(leitura.orientacao, OrientacaoLeitura.paisagem);
      expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.paisagem);
      // O sheet fecha e a linha passa a mostrar a escolha.
      expect(find.text('paisagem'), findsOneWidget);
      expect(find.text('orientacaoAutomatica'), findsNothing);

      // Voltar para a leitura mantém a escolha.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ConfiguracaoLeituraView), findsNothing);
      expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.paisagem);

      // Pelas opções de leitura (botão central), com um capítulo aberto.
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('opcoesLeitura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.byType(OpcoesLeituraSheet), findsNothing);
      expect(find.byType(ConfiguracaoLeituraView), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Sair da leitura solta a orientação.
      viewModel.dispose();
      await tester.pump();
      expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.automatica);
      await tester.pumpWidget(const SizedBox());
    });

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
      expect(find.text('configuracoesLeitura'), findsOneWidget);
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

    testWidgets('marca-texto: pinta o trecho selecionado, guarda, mostra ao tocar e remove', (tester) async {
      final vm = await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '2'));
      await tester.pumpAndSettle();

      Future<void> selecionar() async {
        final gesto = await tester.startGesture(posicaoPalavra(tester, 'Gênesis 2 texto 1', 'texto'));
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
        await gesto.moveTo(posicaoPalavra(tester, 'Gênesis 2 texto 2', 'Gênesis'));
        await tester.pump();
        await gesto.up();
        await tester.pumpAndSettle();
      }

      int? viewModelDestacado() => vm.versiculoDestacado;
      // Selecionar já marca, na cor das Configurações de leitura; o sheet oferece "Desmarcar texto".
      leitura.setCorMarcaTexto(HighlightColor.verde);
      await selecionar();
      expect(find.byTooltip('marcaTexto_verde'), findsNothing);
      expect(find.text('desmarcarTexto'), findsOneWidget);
      // De cima para baixo: o texto, as tags, desmarcar e as ações.
      final yTexto = tester.getTopLeft(find.byKey(const ValueKey('textoTrecho'))).dy;
      final yTags = tester.getTopLeft(find.byType(TagsTrecho)).dy;
      final yDesmarcar = tester.getTopLeft(find.text('desmarcarTexto')).dy;
      final yAcoes = tester.getTopLeft(find.text('copiar')).dy;
      expect(yTexto < yTags && yTags < yDesmarcar && yDesmarcar < yAcoes, isTrue);
      await fecharSheet(tester, find.byKey(const ValueKey('textoTrecho')));

      final chave = '${_arc.versaId}:${_genesis.livrId}:2';
      expect(marcaTexto.salvas[chave], [
        (versId: 1201, inicio: 10, fim: 17, cor: HighlightColor.verde),
        (versId: 1202, inicio: 0, fim: 7, cor: HighlightColor.verde),
      ]);
      // O trecho fica pintado na página.
      final spans = (tester.widget<Text>(find.textContaining('Gênesis 2 texto 1').first).textSpan! as TextSpan)
          .children!
          .whereType<TextSpan>();
      expect(spans.where((t) => t.style?.backgroundColor != null).map((t) => t.text), ['texto 1']);

      // Tocar no trecho marcado mostra o trecho inteiro (dos dois versículos), com a referência.
      await tester.tapAt(posicaoPalavra(tester, 'Gênesis 2 texto 2', 'Gênesis'));
      await tester.pumpAndSettle();
      expect(find.text('Gênesis 2:1-2'), findsOneWidget);
      expect(find.text('texto 1 Gênesis'), findsOneWidget);
      expect(viewModelDestacado(), isNull);
      await tester.tap(find.text('desmarcarTexto'));
      await tester.pumpAndSettle();
      expect(marcaTexto.salvas[chave], isEmpty);
      // O sheet continua aberto e oferece marcar de novo.
      expect(find.text('marcarTexto'), findsOneWidget);
    });

    /// Abre Gênesis 2 e seleciona de "texto 1" (versículo 1) a "Gênesis" (versículo 2), abrindo o trecho.
    Future<void> selecionarTrechoGenesis2(WidgetTester tester) async {
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
    }

    testWidgets('a cor do marca-texto escolhida nas configurações é a usada ao marcar o trecho', (tester) async {
      await montar(tester);
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.text('cor_amarelo'), findsOneWidget);
      await abrirLinha(tester, 'corMarcaTexto');
      await tester.tap(find.text('cor_verde'));
      await tester.pumpAndSettle();
      expect(leitura.corMarcaTexto, HighlightColor.verde);
      expect(find.text('cor_verde'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await selecionarTrechoGenesis2(tester);
      expect(marcaTexto.salvas.values.expand((m) => m).map((m) => m.cor).toSet(), {HighlightColor.verde});
    });

    testWidgets('tag no trecho: criada na hora com a cor sugerida, pinta o trecho na cor dela', (tester) async {
      await montar(tester);
      await selecionarTrechoGenesis2(tester);
      expect(find.text('copiar'), findsOneWidget);
      expect(find.text('compartilhar'), findsOneWidget);
      expect(find.text('ouvir'), findsOneWidget);

      // Escolhe a tag direto no sheet do trecho: "Nova tag" com a cor sugerida (a primeira livre) já marcada.
      await tester.tap(find.text('novaTag'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byTooltip('corTag_azul'), matching: find.byIcon(Icons.check)), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('novaTagTrecho')), 'Criação');
      await tester.tap(find.byTooltip('corTag_verde'));
      await tester.pump();
      await tester.tap(find.byTooltip('criarTag'));
      await tester.pumpAndSettle();
      expect(anotacao.tagsSalvas.map((t) => (t.nome, t.cor)), [('Criação', CorTag.verde)]);
      final tagId = anotacao.tagsSalvas.single.id;

      final chave = '${_arc.versaId}:${_genesis.livrId}:2';
      final trecho = anotacao.salvas[chave]!.single;
      expect((trecho.versIdInicio, trecho.inicio, trecho.versIdFim, trecho.fim, trecho.texto), (1201, 10, 1202, 7, ''));
      expect(trecho.tags, [tagId]);
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Criação')).selected, isTrue);

      // Fechado o sheet, o trecho fica pintado na cor da tag.
      Navigator.of(tester.element(find.byType(TagsTrecho))).pop();
      await tester.pumpAndSettle();
      final spans = (tester.widget<Text>(find.textContaining('Gênesis 2 texto 1').first).textSpan! as TextSpan)
          .children!
          .whereType<TextSpan>();
      final pintados = spans.where((t) => t.style?.backgroundColor != null);
      expect(pintados.map((t) => t.text), ['texto 1']);
      expect(pintados.single.style?.backgroundColor, CorTag.verde.cor.withValues(alpha: 0.28));

      // Tocar no trecho abre o sheet com a tag marcada; desmarcar a única tag (sem texto) apaga o trecho.
      await tester.tapAt(posicaoPalavra(tester, 'Gênesis 2 texto 1', 'texto'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Criação')).selected, isTrue);
      await tester.tap(find.widgetWithText(FilterChip, 'Criação'));
      await tester.pumpAndSettle();
      expect(anotacao.salvas[chave], isEmpty);
    });

    testWidgets('anotação: texto digitado e ditado; mantém as tags do trecho ao salvar e ao excluir', (tester) async {
      await montar(tester);
      await selecionarTrechoGenesis2(tester);
      await tester.tap(find.text('novaTag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('novaTagTrecho')), 'Fé');
      await tester.tap(find.byTooltip('criarTag'));
      await tester.pumpAndSettle();
      final tagId = anotacao.tagsSalvas.single.id;

      await tester.tap(find.text('anotar'));
      await tester.pumpAndSettle();
      expect(find.byType(AnotacaoTrechoSheet), findsOneWidget);
      expect(find.text('tags'), findsNothing);

      // Digita uma parte e dita o resto pelo microfone do campo (ditado do sistema): o falado vai para o fim.
      await tester.enterText(find.byKey(const ValueKey('textoAnotacao')), 'Deus');
      ditado.falado = 'criou tudo';
      await tester.tap(find.byTooltip('ditar'));
      await tester.pumpAndSettle();
      expect(ditado.idioma, 'pt-BR');
      expect(find.text('Deus criou tudo'), findsOneWidget);
      // Cancelar o ditado não mexe no texto.
      ditado.falado = null;
      await tester.tap(find.byTooltip('ditar'));
      await tester.pumpAndSettle();
      expect(find.text('Deus criou tudo'), findsOneWidget);

      await tester.tap(find.text('salvar'));
      await tester.pumpAndSettle();
      expect(find.text('anotacaoSalva'), findsOneWidget);
      final chave = '${_arc.versaId}:${_genesis.livrId}:2';
      expect(anotacao.salvas[chave]!.single.texto, 'Deus criou tudo');
      expect(anotacao.salvas[chave]!.single.tags, [tagId]);

      // Tocar no trecho abre o sheet com a anotação.
      await tester.tapAt(posicaoPalavra(tester, 'Gênesis 2 texto 1', 'texto'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('anotacaoTrecho')), findsOneWidget);
      expect(find.text('Deus criou tudo'), findsOneWidget);

      // Excluir a anotação apaga só o texto: a tag do trecho fica.
      await tester.tap(find.text('editarAnotacao'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('excluir'));
      await tester.pumpAndSettle();
      expect(find.text('anotacaoExcluida'), findsOneWidget);
      expect(anotacao.salvas[chave]!.single.texto, '');
      expect(anotacao.salvas[chave]!.single.tags, [tagId]);
    });

    testWidgets('compartilhar: o trecho com a referência e a mensagem digitada', (tester) async {
      await montar(tester);
      await selecionarTrechoGenesis2(tester);
      await tester.tap(find.text('compartilhar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('mensagemCompartilhar')), 'Leiam isto');
      await tester.tap(find.widgetWithText(FilledButton, 'compartilhar'));
      await tester.pumpAndSettle();
      expect(compartilhamento.compartilhados, ['Leiam isto\n\n"texto 1 Gênesis" (Gênesis 2:1-2)']);
    });

    testWidgets('gerenciar tags nas configurações de leitura: cria, renomeia e apaga', (tester) async {
      final vm = await montar(tester);
      await tester.tap(find.text('Gênesis'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CapituloChip, '1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('gerenciarTags'), 100);
      await tester.ensureVisible(find.text('gerenciarTags'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('gerenciarTags'));
      await tester.pumpAndSettle();
      expect(find.byType(TagsLeituraSheet), findsOneWidget);
      expect(find.descendant(of: find.byType(TagsLeituraSheet), matching: find.text('nenhumaTag')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('novaTag')), 'Fé');
      await tester.tap(find.byTooltip('criarTag'));
      await tester.pumpAndSettle();
      // Nome repetido (sem diferenciar maiúsculas) não é aceito.
      await tester.enterText(find.byKey(const ValueKey('novaTag')), 'fé');
      await tester.tap(find.byTooltip('criarTag'));
      await tester.pumpAndSettle();
      expect(find.text('tagRepetida'), findsOneWidget);
      expect(vm.tags.map((t) => t.nome), ['Fé']);

      await tester.tap(find.byTooltip('renomearTag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ValueKey('renomearTag_${vm.tags.single.id}')), 'Fé e esperança');
      await tester.tap(find.byTooltip('salvar'));
      await tester.pumpAndSettle();
      expect(anotacao.tagsSalvas.map((t) => t.nome), ['Fé e esperança']);

      // Tocar na bolinha abre a paleta da tag (abaixo da paleta da tag nova); a cor escolhida é guardada.
      expect(anotacao.tagsSalvas.single.cor, CorTag.azul);
      await tester.tap(find.byTooltip('corTag'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('corTag_roxo'), findsNWidgets(2));
      await tester.tap(find.byTooltip('corTag_roxo').last);
      await tester.pumpAndSettle();
      expect(anotacao.tagsSalvas.single.cor, CorTag.roxo);
      expect(find.byTooltip('corTag_roxo'), findsOneWidget);

      await tester.tap(find.byTooltip('excluirTag'));
      await tester.pumpAndSettle();
      expect(anotacao.tagsSalvas, isEmpty);
      expect(find.descendant(of: find.byType(TagsLeituraSheet), matching: find.text('nenhumaTag')), findsOneWidget);
    });

    test('anotação: grava, acha pela posição, indica no versículo e apaga sem texto nem tags', () {
      const versiculos = [
        VersiculoTextoModel(versId: 1, versNumero: 1, versTexto: 'abcdefghij', livrId: 1, livrNome: 'G', capiNumero: 1),
        VersiculoTextoModel(versId: 2, versNumero: 2, versTexto: 'klmnopqrst', livrId: 1, livrNome: 'G', capiNumero: 1),
      ];
      final agora = DateTime(2026, 11, 21);
      final anotacoes = BibliaLeituraUseCase.comAnotacao(
        const [],
        versiculos,
        (indice: 0, offset: 5),
        (indice: 1, offset: 3),
        texto: '  nota  ',
        tags: const ['t1'],
        agora: agora,
      );
      final a = anotacoes.single;
      expect((a.versIdInicio, a.inicio, a.versIdFim, a.fim, a.texto), (1, 5, 2, 3, 'nota'));

      expect(BibliaLeituraUseCase.anotacaoEm(anotacoes, versiculos, 0, 4), isNull);
      expect(BibliaLeituraUseCase.anotacaoEm(anotacoes, versiculos, 0, 5), a);
      expect(BibliaLeituraUseCase.anotacaoEm(anotacoes, versiculos, 1, 2), a);
      expect(BibliaLeituraUseCase.anotacaoEm(anotacoes, versiculos, 1, 3), isNull);
      expect(BibliaLeituraUseCase.trechosAnotados(anotacoes, versiculos, 0), [(inicio: 5, fim: 10, anotacao: a)]);
      expect(BibliaLeituraUseCase.trechosAnotados(anotacoes, versiculos, 1), [(inicio: 0, fim: 3, anotacao: a)]);

      // A cor da anotação é a da primeira tag marcada que ainda existe; sem tag, nenhuma.
      const tags = [(id: 't1', nome: 'Fé', cor: CorTag.roxo), (id: 't2', nome: 'Paz', cor: CorTag.verde)];
      expect(BibliaLeituraUseCase.corDaAnotacao(a, tags), CorTag.roxo);
      expect(BibliaLeituraUseCase.corDaAnotacao(a, [tags.last]), isNull);
      expect(
        BibliaLeituraUseCase.anotacaoDoTrecho(anotacoes, versiculos, (indice: 0, offset: 5), (indice: 1, offset: 3)),
        a,
      );

      // Tirar a única tag de uma anotação com texto mantém a anotação; sem texto, apaga.
      expect(BibliaLeituraUseCase.semTag(anotacoes, 't1').single.tags, isEmpty);
      final soTag = BibliaLeituraUseCase.comAnotacao(
        anotacoes,
        versiculos,
        (indice: 0, offset: 5),
        (indice: 1, offset: 3),
        id: a.id,
        texto: '',
        tags: const ['t1'],
        agora: agora,
      );
      expect(BibliaLeituraUseCase.semTag(soTag, 't1'), isEmpty);

      final vazia = BibliaLeituraUseCase.comAnotacao(
        anotacoes,
        versiculos,
        (indice: 0, offset: 5),
        (indice: 1, offset: 3),
        id: a.id,
        texto: '   ',
        tags: const [],
        agora: agora,
      );
      expect(vazia, isEmpty);
    });

    test('anotação e tags: grava e lê o JSON, ignorando itens inválidos', () {
      final anotacoes = [
        (
          id: 'a',
          versIdInicio: 1,
          inicio: 2,
          versIdFim: 3,
          fim: 4,
          texto: 'nota',
          tags: ['t'],
          atualizadaEm: DateTime(2026, 11, 21, 10),
        ),
      ];
      final lidas = AnotacaoArmazenamentoLocal.decodificar(AnotacaoArmazenamentoLocal.codificar(anotacoes));
      expect(lidas.single.id, 'a');
      expect(lidas.single.tags, ['t']);
      expect(lidas.single.atualizadaEm, DateTime(2026, 11, 21, 10));
      expect(AnotacaoArmazenamentoLocal.decodificar('[{"id":"a"}]'), isEmpty);
      expect(AnotacaoArmazenamentoLocal.decodificar('lixo'), isEmpty);

      const tags = [(id: 't', nome: 'Fé', cor: CorTag.verde)];
      expect(AnotacaoArmazenamentoLocal.decodificarTags(AnotacaoArmazenamentoLocal.codificarTags(tags)), tags);
      expect(AnotacaoArmazenamentoLocal.decodificarTags(null), isEmpty);
      // Tag gravada sem cor (ou com cor desconhecida) fica cinza.
      expect(AnotacaoArmazenamentoLocal.decodificarTags('[{"id":"t","n":"Fé"},{"id":"u","n":"Paz","c":"x"}]'), [
        (id: 't', nome: 'Fé', cor: CorTag.cinza),
        (id: 'u', nome: 'Paz', cor: CorTag.cinza),
      ]);
    });

    test('tags: nome vazio, longo ou repetido não serve; ordem alfabética', () {
      const tags = [(id: '1', nome: 'Fé', cor: CorTag.azul), (id: '2', nome: 'amor', cor: CorTag.verde)];
      expect(BibliaLeituraUseCase.validarTag('  ', tags), 'tagNomeVazio');
      expect(BibliaLeituraUseCase.validarTag('x' * 31, tags), 'tagNomeLongo');
      expect(BibliaLeituraUseCase.validarTag(' FÉ ', tags), 'tagRepetida');
      expect(BibliaLeituraUseCase.validarTag('Fé', tags, exceto: '1'), isNull);
      expect(BibliaLeituraUseCase.validarTag('Graça', tags), isNull);
      expect(BibliaLeituraUseCase.ordenarTags(tags).map((t) => t.nome), ['amor', 'Fé']);
      // Tag nova pega a primeira cor ainda não usada; com todas usadas, o rodízio.
      expect(BibliaLeituraUseCase.proximaCor(const []), CorTag.azul);
      expect(BibliaLeituraUseCase.proximaCor(tags), CorTag.amarelo);
      final todas = [for (final (i, c) in CorTag.values.indexed) (id: '$i', nome: '$i', cor: c)];
      expect(BibliaLeituraUseCase.proximaCor(todas), CorTag.azul);
    });

    test('16 cores de tag; a paleta tem todas, sem repetir', () {
      expect(CorTag.values, hasLength(16));
      expect(CorTag.paleta.toSet(), CorTag.values.toSet());
      expect(CorTag.paleta, hasLength(CorTag.values.length));
      expect(CorTag.doNome('turquesa'), CorTag.turquesa);
    });

    test('compartilhar: mensagem opcional antes do trecho', () {
      expect(BibliaLeituraUseCase.textoCompartilhado('texto', 'Gn 1:1'), '"texto" (Gn 1:1)');
      expect(BibliaLeituraUseCase.textoCompartilhado('texto', 'Gn 1:1', mensagem: '  '), '"texto" (Gn 1:1)');
      expect(BibliaLeituraUseCase.textoCompartilhado('texto', 'Gn 1:1', mensagem: 'Veja'), 'Veja\n\n"texto" (Gn 1:1)');
    });

    test('marca-texto: cor nova substitui só a parte do trecho; desmarcar corta a marcação', () {
      const versiculos = [
        VersiculoTextoModel(versId: 1, versNumero: 1, versTexto: 'abcdefghij', livrId: 1, livrNome: 'G', capiNumero: 1),
      ];
      const amarelo = (versId: 1, inicio: 0, fim: 10, cor: HighlightColor.amarelo);
      final marcadas = BibliaLeituraUseCase.marcar([amarelo], versiculos, (indice: 0, offset: 3), (
        indice: 0,
        offset: 6,
      ), HighlightColor.azul);
      expect(marcadas, [
        (versId: 1, inicio: 0, fim: 3, cor: HighlightColor.amarelo),
        (versId: 1, inicio: 6, fim: 10, cor: HighlightColor.amarelo),
        (versId: 1, inicio: 3, fim: 6, cor: HighlightColor.azul),
      ]);
      expect(
        BibliaLeituraUseCase.trechoMarcado([amarelo], versiculos, (indice: 0, offset: 2), (indice: 0, offset: 4)),
        isTrue,
      );
      expect(
        BibliaLeituraUseCase.desmarcar([amarelo], versiculos, (indice: 0, offset: 0), (indice: 0, offset: 10)),
        isEmpty,
      );
    });

    test('marca-texto: grava e lê o JSON, ignorando itens inválidos', () {
      const marcas = [(versId: 1, inicio: 2, fim: 5, cor: HighlightColor.rosa)];
      expect(MarcaTextoArmazenamentoLocal.decodificar(MarcaTextoArmazenamentoLocal.codificar(marcas)), marcas);
      expect(
        MarcaTextoArmazenamentoLocal.decodificar('[{"v":1,"i":5,"f":2,"c":"rosa"},{"v":1,"i":0,"f":1,"c":"x"}]'),
        isEmpty,
      );
      expect(MarcaTextoArmazenamentoLocal.decodificar('lixo'), isEmpty);
      expect(MarcaTextoArmazenamentoLocal.decodificar(null), isEmpty);
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

    testWidgets('áudio: abrir um menu ou sheet por cima da leitura para a narração', (tester) async {
      final viewModel = await abrirGenesis1(tester);
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pump();
      expect(viewModel.narrando, isTrue);

      await tester.tap(find.byTooltip('opcoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.byType(OpcoesLeituraSheet), findsOneWidget);
      expect(viewModel.narrando, isFalse);
      expect(voz.parou, isTrue);
    });

    testWidgets('áudio: sair da leitura (voltar) para a narração', (tester) async {
      BibliaLeituraViewmodel? viewModel;
      final router = GoRouter(
        initialLocation: Routes.home,
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (context, state) => Scaffold(
              body: TextButton(onPressed: () => context.push(Routes.bibliaLeitura), child: const Text('telaHome')),
            ),
          ),
          GoRoute(
            path: Routes.bibliaLeitura,
            builder: (context, state) => BibliaLeituraView(
              viewModel: viewModel ??= BibliaLeituraViewmodel(
                bibliaLeituraUseCase: leituraUseCase(),
                versiculoIndicacaoUseCase: indicacaoUseCase(),
                versiculoReacaoUseCase: reacaoUseCase(),
                versiculoIndicacaoUsuarioUseCase: indicadoUseCase(),
                destino: LeituraDestino(versaId: _arc.versaId, livrId: _genesis.livrId, capiNumero: 1),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [_TestLocalizationsDelegate(), DefaultMaterialLocalizations.delegate],
        ),
      );
      await tester.tap(find.text('telaHome'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pump();
      expect(viewModel!.narrando, isTrue);

      await tester.pageBack();
      await tester.pump();
      expect(voz.parou, isTrue);
      expect(viewModel!.narrando, isFalse);
      await tester.pumpAndSettle();
      expect(find.text('telaHome'), findsOneWidget);
    });

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

    testWidgets('áudio: usa a última voz pt-BR e a velocidade padrão; a escolhida nas opções vale depois', (
      tester,
    ) async {
      await abrirGenesis1(tester);
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.ultimaVoz?.nome, 'pt-br-comum');
      expect(voz.ultimaVelocidade, BibliaLeituraUseCase.velocidadePadrao);
      await tester.tap(find.byTooltip('pararNarracao'));
      await tester.pumpAndSettle();

      leitura.vozNarracao = 'pt-br-neural';
      leitura.velocidadeNarracao = 0.6;
      await tester.tap(find.byTooltip('ouvirCapitulo'));
      await tester.pumpAndSettle();
      expect(voz.ultimaVoz?.nome, 'pt-br-neural');
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

    testWidgets('a engrenagem mostra as Configurações de leitura e as do app; sem login, a do app abre o login', (
      tester,
    ) async {
      await montar(tester);
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      expect(find.text('configuracoesLeitura'), findsOneWidget);
      await tester.tap(find.text('configuracoesApp'));
      await tester.pumpAndSettle();
      expect(find.text('telaConfiguracaoApp'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      logado = false;
      await montar(tester);
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      expect(find.text('entreParaAcessar'), findsOneWidget);
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfiguracaoLeituraView), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesApp'));
      await tester.pumpAndSettle();
      // Sem login, explica que é restrita e deixa voltar ou continuar para o login.
      expect(find.text('funcionalidadeRestritaLogin'), findsOneWidget);
      await tester.tap(find.text('voltar'));
      await tester.pumpAndSettle();
      expect(find.text('funcionalidadeRestritaLogin'), findsNothing);
      expect(find.text('telaLogin'), findsNothing);

      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesApp'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('continuarLogin')));
      await tester.pumpAndSettle();
      expect(find.text('telaLogin'), findsOneWidget);
    });

    testWidgets('brilho e orientação da leitura valem ao abrir a leitura e voltam aos do sistema ao sair', (
      tester,
    ) async {
      leitura
        ..setBrilhoLeitura(0.8)
        ..setOrientacao(OrientacaoLeitura.paisagem);
      await montar(tester);
      expect(brilho.definidos.last, 0.8);
      expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.paisagem);

      await tester.pumpWidget(const SizedBox());
      expect(brilho.restaurado, isTrue);
      expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.automatica);
    });

    testWidgets(
      'nas Configurações do app (fora da leitura) brilho e orientação são os do sistema; ao voltar, os da leitura',
      (tester) async {
        leitura
          ..setBrilhoLeitura(0.8)
          ..setOrientacao(OrientacaoLeitura.paisagem);
        await montar(tester);
        await tester.tap(find.byTooltip('configuracoes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('configuracoesApp'));
        await tester.pumpAndSettle();
        expect(find.text('telaConfiguracaoApp'), findsOneWidget);
        expect(brilho.restaurado, isTrue);
        expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.automatica);

        brilho.definidos.clear();
        GoRouter.of(tester.element(find.text('telaConfiguracaoApp'))).pop();
        await tester.pumpAndSettle();
        expect(brilho.definidos, [0.8]);
        expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.paisagem);
      },
    );

    testWidgets('o brilho escolhido nas Configurações de leitura é guardado', (tester) async {
      await montar(tester);
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      await abrirLinha(tester, 'brilho');
      final slider = find.byKey(const ValueKey('brilho'));
      await tester.tapAt(tester.getTopRight(slider) - const Offset(8, -12));
      await tester.pumpAndSettle();
      expect(leitura.brilhoLeitura, greaterThan(0.9));
    });

    testWidgets('sem login, a versão aparece mas trocar pede o login (índice e configurações)', (tester) async {
      logado = false;
      final viewModel = await montar(tester);
      final versaoAntes = viewModel.versao?.versaId;
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      expect(find.text('${viewModel.versao!.versaCodigo} · ${viewModel.versao!.versaNome}'), findsOneWidget);

      // No índice: explica e deixa voltar.
      await tester.tap(find.byKey(const ValueKey('versaoSemLogin')));
      await tester.pumpAndSettle();
      expect(find.text('selecaoVersaoRestritaLogin'), findsOneWidget);
      await tester.tap(find.text('voltar'));
      await tester.pumpAndSettle();
      expect(find.text('selecaoVersaoRestritaLogin'), findsNothing);

      // Nas configurações: a linha tem cadeado; continuar abre o login (sem abrir a tela de versões).
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('abrirVersao')));
      await tester.pumpAndSettle();
      expect(find.byType(VersaoBibliaView), findsNothing);
      expect(find.text('selecaoVersaoRestritaLogin'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('continuarLogin')));
      await tester.pumpAndSettle();
      expect(find.text('telaLogin'), findsOneWidget);
      expect(viewModel.versao?.versaId, versaoAntes);
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

    /// Abre Gênesis 2 e as Configurações de leitura (pelas opções de leitura).
    Future<BibliaLeituraViewmodel> abrirConfiguracoes(WidgetTester tester) async {
      final viewModel = await abrirOpcoes(tester);
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      return viewModel;
    }

    Future<void> voltarParaLeitura(WidgetTester tester) async {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    testWidgets('as opções de leitura têm as Configurações de leitura e as do app', (tester) async {
      await abrirOpcoes(tester);
      expect(find.text('configuracoesLeitura'), findsOneWidget);
      await tester.tap(find.text('configuracoesApp'));
      await tester.pumpAndSettle();
      expect(find.text('telaConfiguracaoApp'), findsOneWidget);
    });

    testWidgets('opções de leitura: escolhe o que fazer ao passar a página', (tester) async {
      await abrirOpcoes(tester);
      expect(find.text('aoPassarPagina'), findsOneWidget);
      await tester.tap(find.text('perguntar'));
      await tester.pumpAndSettle();
      expect(leitura.marcarAoPassar, MarcarAoPassar.perguntar);
    });

    testWidgets('configurações de leitura: o tamanho da fonte aumenta o texto e é guardado', (tester) async {
      await abrirOpcoes(tester);
      Navigator.of(tester.element(find.byType(OpcoesLeituraSheet))).pop();
      await tester.pumpAndSettle();
      double tamanhoTexto() {
        final texto = tester.widget<Text>(find.textContaining('Gênesis 2 texto 1').first);
        final spans = (texto.textSpan! as TextSpan).children!;
        return spans.last.style!.fontSize!;
      }

      final antes = tamanhoTexto();
      await tester.tap(find.byTooltip('configuracoes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('configuracoesLeitura'));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      await abrirLinha(tester, 'tamanhoFonte');
      final slider = find.byKey(const ValueKey('tamanhoFonte'));
      expect(find.byKey(const ValueKey('previaFonte')), findsOneWidget);
      await tester.tapAt(tester.getTopRight(slider) - const Offset(8, -12));
      await tester.pumpAndSettle();
      expect(leitura.escalaFonte, BibliaLeituraUseCase.escalaFonteMaxima);
      await fecharSheet(tester, slider);
      expect(find.text('${(BibliaLeituraUseCase.escalaFonteMaxima * 100).round()}%'), findsOneWidget);
      await voltarParaLeitura(tester);
      expect(tamanhoTexto(), greaterThan(antes));
    });

    testWidgets('configurações de leitura: desligar as setas deixa só o botão de opções na navegação', (tester) async {
      await abrirConfiguracoes(tester);
      await tester.ensureVisible(find.text('mostrarSetasNavegacao'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('mostrarSetasNavegacao'));
      await tester.pumpAndSettle();
      expect(leitura.mostrarSetas, isFalse);
      await voltarParaLeitura(tester);
      expect(find.byTooltip('proximoCapitulo'), findsNothing);
      expect(find.byTooltip('capituloAnterior'), findsNothing);
      expect(find.byTooltip('opcoesLeitura'), findsOneWidget);
    });

    testWidgets('configurações de leitura: o tema escolhido é guardado e vale só na leitura', (tester) async {
      await abrirConfiguracoes(tester);
      expect(find.text('temaDoApp'), findsOneWidget);
      await abrirLinha(tester, 'tema');
      await tester.tap(find.text('creme'));
      await tester.pumpAndSettle();
      expect(leitura.temaLeitura, TemaApp.creme);

      await abrirLinha(tester, 'tema');
      await tester.tap(find.text('escuro'));
      await tester.pumpAndSettle();
      expect(leitura.temaLeitura, TemaApp.escuro);
      // A página de configurações segue o tema do app; a leitura fica escura.
      expect(Theme.of(tester.element(find.text('escuro'))).brightness, Brightness.light);
      await voltarParaLeitura(tester);
      expect(Theme.of(tester.element(find.byType(PageCurlView))).brightness, Brightness.dark);
    });

    testWidgets('configurações de leitura: o brilho muda a tela e volta ao do sistema ao sair', (tester) async {
      final viewModel = await abrirConfiguracoes(tester);
      expect(viewModel.brilho, 0.5);
      await abrirLinha(tester, 'brilho');
      final slider = find.byKey(const ValueKey('brilho'));
      expect(slider, findsOneWidget);

      await tester.tapAt(tester.getTopRight(slider) - const Offset(8, -12));
      await tester.pumpAndSettle();
      expect(brilho.definidos.last, greaterThan(0.9));

      viewModel.dispose();
      await tester.pump();
      expect(brilho.restaurado, isTrue);
      // Desmonta a tela antes do fim do teste: o viewmodel já foi descartado.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('configurações de leitura: a versão abre a tela de versões e troca a da leitura', (tester) async {
      final viewModel = await abrirConfiguracoes(tester);
      expect(find.text('versaoBiblia'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('abrirVersao')));
      await tester.pumpAndSettle();
      expect(find.byType(VersaoBibliaView), findsOneWidget);
      final nvi = viewModel.versoes.firstWhere((v) => v.versaCodigo == 'NVI');
      await tester.tap(find.byKey(ValueKey('versao_${nvi.versaId}')));
      await tester.pumpAndSettle();
      expect(find.byType(VersaoBibliaView), findsNothing);
      expect(viewModel.versao?.versaCodigo, 'NVI');
      expect(find.text('NVI · ${nvi.versaNome}'), findsOneWidget);
    });

    testWidgets('configurações de leitura: a voz é escolhida por idioma, país e nome amigável', (tester) async {
      final viewModel = await abrirConfiguracoes(tester);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('abrirVoz')), 100);
      await tester.ensureVisible(find.byKey(const ValueKey('abrirVoz')));
      await tester.pumpAndSettle();
      expect(find.text('voz 2 · 🇧🇷'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('abrirVoz')));
      await tester.pumpAndSettle();
      expect(find.byType(VozNarracaoView), findsOneWidget);
      // Começa no idioma e país da voz atual: as duas pt-BR, com nomes amigáveis.
      expect(find.text('voz 1'), findsOneWidget);
      expect(find.text('voz 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('voz_pt-pt')), findsNothing);

      // O ▶ toca um exemplo sem escolher.
      await tester.tap(find.byTooltip('ouvirVoz').first);
      await tester.pump();
      expect(voz.ultimaVoz?.nome, 'pt-br-neural');
      expect(viewModel.vozNarracao?.nome, 'pt-br-comum');
      voz.terminarFala();
      await tester.pump();

      // Outro país do português: Portugal.
      await tester.tap(find.text('🇧🇷  BR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🇵🇹  PT').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('voz_pt-pt')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('voz_pt-pt')));
      await tester.pumpAndSettle();
      expect(viewModel.vozNarracao?.nome, 'pt-pt');
      expect(leitura.vozNarracao, 'pt-pt');

      // Outro idioma: inglês.
      await tester.tap(find.text('PT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('voz_en-us')), findsOneWidget);
      expect(find.text('🇺🇸  US'), findsOneWidget);
      voz.terminarFala();
    });

    testWidgets('configurações de leitura: restaurar o padrão volta fonte, aparência, narração e orientação', (
      tester,
    ) async {
      final viewModel = await abrirConfiguracoes(tester);
      leitura
        ..setEscalaFonte(BibliaLeituraUseCase.escalaFonteMaxima)
        ..setMostrarSetas(false)
        ..setVozNarracao('pt-pt')
        ..setVelocidadeNarracao(0.7)
        ..setNarracaoContinua(true)
        ..setTemaLeitura(TemaApp.escuro)
        ..setCorMarcaTexto(HighlightColor.rosa)
        ..setOrientacao(OrientacaoLeitura.paisagem);

      await tester.tap(find.byTooltip('restaurarPadrao'));
      await tester.pumpAndSettle();
      expect(find.text('restaurarPadraoPergunta'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirmarRestaurarPadrao')));
      await tester.pumpAndSettle();

      expect(leitura.escalaFonte, 1);
      expect(leitura.mostrarSetas, isTrue);
      expect(leitura.vozNarracao, isNull);
      expect(viewModel.vozNarracao?.nome, 'pt-br-comum');
      expect(leitura.velocidadeNarracao, BibliaLeituraUseCase.velocidadePadrao);
      expect(leitura.narracaoContinua, isFalse);
      expect(leitura.temaLeitura, TemaApp.sistema);
      expect(leitura.orientacao, OrientacaoLeitura.automatica);
      expect(leitura.corMarcaTexto, HighlightColor.amarelo);
      expect(orientacaoTela.aplicadas.last, OrientacaoLeitura.automatica);
      expect(brilho.restaurado, isTrue);
      expect(find.text('padraoRestaurado'), findsOneWidget);
    });

    testWidgets('configurações de leitura: sem suporte a brilho, o ajuste não aparece', (tester) async {
      brilho = _FakeBrilhoTela(suportado: false);
      await abrirConfiguracoes(tester);
      expect(find.text('tamanhoFonte'), findsOneWidget);
      expect(find.text('brilho'), findsNothing);
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
