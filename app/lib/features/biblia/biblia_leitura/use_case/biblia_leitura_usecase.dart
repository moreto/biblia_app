import 'package:app/config/brilho_tela.dart';
import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/narracao_voz.dart';
import 'package:app/config/ultimo_capitulo_preferencia.dart';
import 'package:app/config/versao_preferencia.dart';
import 'package:commons/commons.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../../../dicionario/use_case/dicionario_usecase.dart';
import '../repository/biblia_leitura_repository.dart';

/// Referência de um capítulo (livro e número), usada para navegar entre capítulos.
typedef CapituloRef = ({int livrId, int capiNumero});

/// Progresso de um livro: capítulos completos, capítulos começados, total de capítulos e a fração (0 a 1) de
/// versículos lidos no livro.
typedef ProgressoLivro = ({int completos, int emAndamento, int total, double fracao});

/// Confirmação mostrada ao usuário depois de marcar ou desmarcar a leitura: [mensagem] é a chave de tradução e
/// [lido] indica se a ação marcou (true) ou desmarcou (false).
typedef FeedbackLeitura = ({String mensagem, bool lido});

/// Ponto em que a leitura abre direto, sem passar pelo índice (ex.: versículo de um renomado).
///
/// Viaja na rota como query string (`/biblia-leitura?versaId=1&livrId=43&capiNumero=3&versNumero=16`); [versaId] e
/// [versNumero] são opcionais.
class LeituraDestino {
  const LeituraDestino({this.versaId, required this.livrId, required this.capiNumero, this.versNumero});

  final int? versaId;
  final int livrId;
  final int capiNumero;
  final int? versNumero;

  CapituloRef get capitulo => (livrId: livrId, capiNumero: capiNumero);

  Map<String, String> toQuery() => {
    if (versaId != null) 'versaId': '$versaId',
    'livrId': '$livrId',
    'capiNumero': '$capiNumero',
    if (versNumero != null) 'versNumero': '$versNumero',
  };

  /// Destino lido da query string; nulo se livro ou capítulo estiverem ausentes ou inválidos.
  static LeituraDestino? fromQuery(Map<String, String> query) {
    final livrId = int.tryParse(query['livrId'] ?? '');
    final capiNumero = int.tryParse(query['capiNumero'] ?? '');
    if (livrId == null || capiNumero == null || livrId < 1 || capiNumero < 1) return null;
    return LeituraDestino(
      versaId: int.tryParse(query['versaId'] ?? ''),
      livrId: livrId,
      capiNumero: capiNumero,
      versNumero: int.tryParse(query['versNumero'] ?? ''),
    );
  }
}

/// Regras da leitura da Bíblia:
/// - o índice da versão define quais capítulos existem (só os que têm versículos na versão);
/// - o progresso vem de `versiculo-reacao/lidos`: um capítulo está lido quando todos os versículos estão marcados;
/// - marcar o capítulo grava todos os versículos de uma vez; se ele já estava completo, desmarca;
/// - cada versículo do capítulo aberto mostra se está lido, pelas reações do usuário no capítulo; ao marcar um
///   versículo, o progresso do capítulo é recalculado a partir dessas reações;
/// - o histórico de leitura lista os capítulos do mais recente para o mais antigo;
/// - o filtro de testamentos mostra o Novo Testamento antes do Antigo;
/// - a leitura abre na versão salva em [versaoPreferencia] (a primeira, se não há versão salva ou se a salva não
///   existe mais) e cada troca de versão é salva;
/// - toda marcação (capítulo ou versículo) devolve uma mensagem de confirmação ao usuário ([mensagemCapitulo] e
///   [mensagemVersiculo]); ao marcar o último versículo que faltava, a mensagem avisa que o capítulo foi concluído;
/// - sem login ([logado] falso) a leitura é pública: só versões, livros, índice e capítulos; progresso, reações,
///   marcações e indicações dependem do usuário e não são carregados;
/// - as opções de leitura guardam o tamanho da fonte (entre [escalaFonteMinima] e [escalaFonteMaxima]) e o tema em
///   [leituraPreferencia]; o brilho muda só o do app, via [brilhoTela], e volta ao do sistema ao sair da leitura;
/// - o toque longo numa palavra do versículo consulta o dicionário ([palavraEm] e [consultarPalavra]); o dicionário
///   exige login, então sem login a consulta devolve `entreParaConsultarDicionario`;
/// - ao passar para o capítulo seguinte, o que ficou para trás é marcado, perguntado ou deixado conforme
///   [marcarAoPassar] ([acaoAoPassar]); só com login, só avançando e só se ele ainda não estiver completo;
/// - a narração lê o capítulo em voz alta a partir do versículo destacado (ou do primeiro), um versículo por vez
///   ([versiculosANarrar], [narrar]); funciona sem login. A voz é a escolhida nas opções ou, sem escolha, a de
///   maior qualidade em português ([vozesNarracao]: pt-BR antes de pt-PT, por qualidade, online antes de local);
///   a velocidade fica entre [velocidadeMinima] e [velocidadeMaxima], um pouco abaixo do normal por padrão. Com
///   [narracaoContinua], ao terminar o capítulo a leitura passa para o próximo e continua.
class BibliaLeituraUseCase {
  BibliaLeituraUseCase({
    required this.bibliaLeituraRepository,
    this.versaoPreferencia,
    this.ultimoCapituloPreferencia,
    this.leituraPreferencia,
    this.brilhoTela,
    this.dicionarioUseCase,
    this.narracaoVoz,
    bool Function()? estaLogado,
  }) : _estaLogado = estaLogado ?? (() => AuthSession.instance.isLogged) {
    Log.print(super.runtimeType);
  }

  final BibliaLeituraRepository bibliaLeituraRepository;

  final bool Function() _estaLogado;

  /// Há usuário logado: libera progresso, marcações e indicações.
  bool get logado => _estaLogado();

  /// Onde a versão escolhida é guardada; nulo não guarda (sempre abre na primeira).
  final VersaoPreferencia? versaoPreferencia;

  /// Onde o último capítulo aberto é guardado (para "Continuar de onde parou"); nulo não guarda.
  final UltimoCapituloPreferencia? ultimoCapituloPreferencia;

  /// Onde ficam o tamanho da fonte e o tema; nulo usa o padrão e não guarda.
  final LeituraPreferencia? leituraPreferencia;

  /// Brilho da tela; nulo (ou plataforma sem suporte) esconde o ajuste de brilho.
  final BrilhoTela? brilhoTela;

  /// Consulta do dicionário pelo toque longo numa palavra; nulo desliga a consulta.
  final DicionarioUseCase? dicionarioUseCase;

  /// Leitura em voz alta; nula esconde o botão de áudio.
  final NarracaoVoz? narracaoVoz;

  /// Idioma da voz da narração.
  static const idiomaNarracao = 'pt-BR';

  bool get narracaoDisponivel => narracaoVoz != null;

  static const velocidadeMinima = 0.3;
  static const velocidadeMaxima = 0.7;

  /// Um pouco mais calma que o normal (0,5) para a leitura da Bíblia.
  static const velocidadePadrao = 0.45;

  /// Frase falada pelo "Ouvir exemplo" das opções de leitura.
  static const exemploNarracao = 'No princípio criou Deus os céus e a terra.';

  double get velocidadeNarracao =>
      (leituraPreferencia?.velocidadeNarracao ?? velocidadePadrao).clamp(velocidadeMinima, velocidadeMaxima).toDouble();

  /// Ao terminar o capítulo, passa a página e continua narrando; desligada por padrão.
  bool get narracaoContinua => leituraPreferencia?.narracaoContinua ?? false;

  void salvarNarracaoContinua(bool continua) => leituraPreferencia?.setNarracaoContinua(continua);

  void salvarVelocidadeNarracao(double velocidade) =>
      leituraPreferencia?.setVelocidadeNarracao(velocidade.clamp(velocidadeMinima, velocidadeMaxima).toDouble());

  List<VozNarracao>? _vozes;

  /// Vozes em português do aparelho, da melhor para a pior; carregadas uma vez. Vazia se não houver ou se falhar.
  Future<List<VozNarracao>> vozesNarracao() async {
    final carregadas = _vozes;
    if (carregadas != null) return carregadas;
    try {
      return _vozes = ordenarVozes(await narracaoVoz?.vozes() ?? const []);
    } catch (e) {
      Log.print('vozes indisponíveis: $e');
      return _vozes = const [];
    }
  }

  /// Só as vozes em português: pt-BR antes de pt-PT, depois pela qualidade e, empatadas, as online (no Android,
  /// em geral as neurais) antes das locais.
  static List<VozNarracao> ordenarVozes(List<VozNarracao> vozes) {
    int pontos(VozNarracao voz) {
      final brasil = voz.locale.toLowerCase().replaceAll('_', '-').startsWith('pt-br') ? 100 : 0;
      final qualidade = switch (voz.qualidade?.toLowerCase()) {
        'premium' || 'very high' => 40,
        'enhanced' || 'high' => 30,
        'default' || 'normal' => 20,
        'low' => 10,
        _ => 15,
      };
      return brasil + qualidade + (voz.online ? 1 : 0);
    }

    final portugues = vozes.where((v) => v.locale.toLowerCase().startsWith('pt')).toList();
    return portugues..sort((a, b) {
      final porPontos = pontos(b).compareTo(pontos(a));
      return porPontos != 0 ? porPontos : a.nome.compareTo(b.nome);
    });
  }

  /// Voz da narração: a escolhida, se ainda estiver instalada; senão a melhor de [vozes]. Nula sem vozes.
  VozNarracao? vozEscolhida(List<VozNarracao> vozes) {
    final nome = leituraPreferencia?.vozNarracao;
    return vozes.where((v) => v.nome == nome).firstOrNull ?? vozes.firstOrNull;
  }

  /// Chave de tradução da qualidade da voz para o seletor.
  static String rotuloQualidade(VozNarracao voz) => switch (voz.qualidade?.toLowerCase()) {
    'premium' || 'very high' || 'enhanced' || 'high' => 'vozQualidadeAlta',
    'low' || 'very low' => 'vozQualidadeBaixa',
    _ => 'vozQualidadeNormal',
  };

  void salvarVozNarracao(VozNarracao voz) => leituraPreferencia?.setVozNarracao(voz.nome);

  /// Versículos que a narração lê: a partir de [aPartirDe] (`versId`), ou do começo se ele for nulo ou não estiver
  /// no capítulo.
  static List<VersiculoTextoModel> versiculosANarrar(List<VersiculoTextoModel> versiculos, int? aPartirDe) {
    final inicio = versiculos.indexWhere((v) => v.versId == aPartirDe);
    return inicio < 0 ? versiculos : versiculos.sublist(inicio);
  }

  /// Fala o [texto] e termina quando a fala acaba (ou é interrompida). Falso se a voz falhou.
  Future<bool> narrar(String texto) async {
    try {
      final voz = vozEscolhida(await vozesNarracao());
      await narracaoVoz?.falar(texto, idioma: idiomaNarracao, voz: voz, velocidade: velocidadeNarracao);
      return narracaoVoz != null;
    } catch (e) {
      Log.print('narração falhou: $e');
      return false;
    }
  }

  /// Interrompe a fala atual.
  Future<void> pararNarracao() async {
    try {
      await narracaoVoz?.parar();
    } catch (e) {
      Log.print('narração não parou: $e');
    }
  }

  static const kEntreParaConsultarDicionario = 'entreParaConsultarDicionario';

  /// Letras (com acentos) que formam uma palavra do versículo; números, pontuação, espaços e hífen a separam.
  static final _letra = RegExp(r'[\p{L}\p{M}]', unicode: true);

  /// Palavra do [texto] na posição [offset] (onde o dedo tocou); nula se ali não há letra (espaço, número do
  /// versículo, pontuação). Tocar logo depois da última letra ainda vale a palavra.
  static String? palavraEm(String texto, int offset) {
    final intervalo = intervaloPalavraEm(texto, offset);
    return intervalo == null ? null : texto.substring(intervalo.inicio, intervalo.fim);
  }

  /// Onde começa e termina (exclusivo) a palavra de [palavraEm]; nulo se ali não há letra.
  static ({int inicio, int fim})? intervaloPalavraEm(String texto, int offset) {
    bool letra(int i) => i >= 0 && i < texto.length && _letra.hasMatch(texto[i]);
    var posicao = offset;
    if (!letra(posicao)) posicao--;
    if (!letra(posicao)) return null;
    var inicio = posicao;
    var fim = posicao + 1;
    while (letra(inicio - 1)) {
      inicio--;
    }
    while (letra(fim)) {
      fim++;
    }
    return (inicio: inicio, fim: fim);
  }

  /// Texto do trecho selecionado de [inicio] a [fim] (versículo pelo índice em [versiculos] e posição no texto
  /// dele, fim exclusivo), com os versículos separados por espaço.
  static String trecho(
    List<VersiculoTextoModel> versiculos,
    ({int indice, int offset}) inicio,
    ({int indice, int offset}) fim,
  ) => [
    for (var i = inicio.indice; i <= fim.indice; i++)
      versiculos[i].versTexto.substring(
        i == inicio.indice ? inicio.offset : 0,
        i == fim.indice ? fim.offset : versiculos[i].versTexto.length,
      ),
  ].map((t) => t.trim()).where((t) => t.isNotEmpty).join(' ');

  /// Referência do trecho: "Gênesis 2:3" ou "Gênesis 2:1-3" ([capitulo] é o título do capítulo).
  static String referenciaTrecho(String capitulo, int versInicio, int versFim) =>
      versInicio == versFim ? '$capitulo:$versInicio' : '$capitulo:$versInicio-$versFim';

  /// Verbetes da [palavra] no dicionário (ou as semelhantes, se não existir). Exige login.
  Future<Result<DicionarioConsulta>> consultarPalavra(String palavra) async {
    final dicionario = dicionarioUseCase;
    if (dicionario == null || !logado) {
      return Result.error(HandledException(message: kEntreParaConsultarDicionario));
    }
    return dicionario.consultar(palavra.toLowerCase());
  }

  static const escalaFonteMinima = 0.8;
  static const escalaFonteMaxima = 1.6;

  /// Multiplicador da fonte dos versículos, limitado à faixa permitida.
  double get escalaFonte =>
      (leituraPreferencia?.escalaFonte ?? 1).clamp(escalaFonteMinima, escalaFonteMaxima).toDouble();

  void salvarEscalaFonte(double escala) =>
      leituraPreferencia?.setEscalaFonte(escala.clamp(escalaFonteMinima, escalaFonteMaxima).toDouble());

  /// O que fazer com o capítulo ao passar para o próximo; sem preferência, pergunta.
  MarcarAoPassar get marcarAoPassar => leituraPreferencia?.marcarAoPassar ?? MarcarAoPassar.perguntar;

  void salvarMarcarAoPassar(MarcarAoPassar valor) => leituraPreferencia?.setMarcarAoPassar(valor);

  /// O que fazer com o capítulo [de] ao passar para [para]: [MarcarAoPassar.nunca] sem login, voltando (ou indo
  /// para fora da [sequencia]) ou quando [de] já está completo ([lidoDe]); senão, a preferência.
  MarcarAoPassar acaoAoPassar(
    List<CapituloRef> sequencia,
    CapituloRef de,
    CapituloRef para,
    CapituloLidoModel? lidoDe,
  ) {
    final origem = sequencia.indexOf(de);
    final destino = sequencia.indexOf(para);
    if (!logado || origem < 0 || destino <= origem || (lidoDe?.completo ?? false)) return MarcarAoPassar.nunca;
    return marcarAoPassar;
  }

  /// Setas anterior/próximo visíveis na navegação; sem preferência, aparecem.
  bool get mostrarSetas => leituraPreferencia?.mostrarSetas ?? true;

  void salvarMostrarSetas(bool mostrar) => leituraPreferencia?.setMostrarSetas(mostrar);

  /// Tema do app; sem preferência, segue o sistema.
  TemaApp get tema => leituraPreferencia?.tema ?? TemaApp.sistema;

  void salvarTema(TemaApp tema) => leituraPreferencia?.setTema(tema);

  /// Brilho atual do app (0 a 1); nulo se não há suporte a brilho.
  Future<double?> brilhoAtual() async {
    final brilho = brilhoTela;
    if (brilho == null) return null;
    try {
      return (await brilho.atual()).clamp(0, 1).toDouble();
    } catch (e) {
      Log.print('brilho indisponível: $e');
      return null;
    }
  }

  /// Define o brilho do app; falhas são ignoradas (o ajuste é só conforto visual).
  Future<void> definirBrilho(double valor) async {
    try {
      await brilhoTela?.definir(valor.clamp(0, 1).toDouble());
    } catch (e) {
      Log.print('brilho não aplicado: $e');
    }
  }

  /// Devolve o brilho ao do sistema.
  Future<void> restaurarBrilho() async {
    try {
      await brilhoTela?.restaurar();
    } catch (e) {
      Log.print('brilho não restaurado: $e');
    }
  }

  Future<Result<List<VersaoModel>>> versoes() => bibliaLeituraRepository.versoes();

  /// Versão em que a leitura abre: a salva, se ainda estiver entre as [versoes]; senão a primeira. Nula se não
  /// há versões.
  VersaoModel? versaoInicial(List<VersaoModel> versoes) {
    final salva = versaoPreferencia?.versaoId;
    for (final versao in versoes) {
      if (versao.versaId == salva) return versao;
    }
    return versoes.firstOrNull;
  }

  /// Versão em que a leitura abre quando há [destino]: a versão do destino, se estiver entre as [versoes]; senão a
  /// de [versaoInicial].
  VersaoModel? versaoDoDestino(List<VersaoModel> versoes, LeituraDestino? destino) {
    final versaId = destino?.versaId;
    for (final versao in versoes) {
      if (versao.versaId == versaId) return versao;
    }
    return versaoInicial(versoes);
  }

  /// O destino pode ser aberto: o capítulo existe no [indice] da versão.
  bool destinoDisponivel(Map<int, List<IndiceCapituloModel>> indice, LeituraDestino destino) =>
      indice[destino.livrId]?.any((c) => c.capiNumero == destino.capiNumero) ?? false;

  /// `versId` do versículo de número [versNumero] no capítulo carregado; nulo se não houver.
  int? versiculoDoDestino(List<VersiculoTextoModel> versiculos, int? versNumero) {
    if (versNumero == null) return null;
    for (final versiculo in versiculos) {
      if (versiculo.versNumero == versNumero) return versiculo.versId;
    }
    return null;
  }

  /// Guarda o capítulo aberto, com ou sem login, para a home oferecer "Continuar de onde parou".
  void salvarUltimoCapitulo(int versaId, CapituloRef ref) =>
      ultimoCapituloPreferencia?.setUltimoCapitulo((versaId: versaId, livrId: ref.livrId, capiNumero: ref.capiNumero));

  /// Guarda a versão escolhida para as próximas aberturas do app.
  void salvarVersao(VersaoModel versao) => versaoPreferencia?.setVersaoId(versao.versaId);

  /// Testamentos na ordem do filtro do índice: Novo antes do Antigo (a API devolve por `test_id` crescente,
  /// então a lista é ordenada por `testId` decrescente).
  Future<Result<List<TestamentoModel>>> testamentos() async {
    final result = await bibliaLeituraRepository.testamentos();
    switch (result) {
      case Ok<List<TestamentoModel>>(value: final testamentos):
        return Result.ok([...testamentos]..sort((a, b) => b.testId.compareTo(a.testId)));
      case Error<List<TestamentoModel>>(error: final error):
        return Result.error(error);
    }
  }

  Future<Result<List<LivroModel>>> livros() => bibliaLeituraRepository.livros();

  Future<Result<List<VersiculoTextoModel>>> capitulo(int versaId, CapituloRef ref) =>
      bibliaLeituraRepository.capitulo(versaId, ref.livrId, ref.capiNumero);

  /// Capítulos da versão agrupados por livro, em ordem; capítulos sem versículos na versão ficam de fora.
  Future<Result<Map<int, List<IndiceCapituloModel>>>> indice(int versaId) async {
    final result = await bibliaLeituraRepository.indice(versaId);
    switch (result) {
      case Ok<List<IndiceCapituloModel>>(value: final capitulos):
        final porLivro = <int, List<IndiceCapituloModel>>{};
        for (final capitulo in capitulos) {
          if (capitulo.versTotal <= 0) continue;
          porLivro.putIfAbsent(capitulo.livrId, () => []).add(capitulo);
        }
        for (final lista in porLivro.values) {
          lista.sort((a, b) => a.capiNumero.compareTo(b.capiNumero));
        }
        return Result.ok(porLivro);
      case Error<List<IndiceCapituloModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Progresso de leitura do usuário na versão, indexado por [CapituloLidoModel.chave].
  Future<Result<Map<String, CapituloLidoModel>>> lidos(int versaId) async {
    final result = await bibliaLeituraRepository.lidos(versaId);
    switch (result) {
      case Ok<List<CapituloLidoModel>>(value: final lidos):
        return Result.ok({for (final lido in lidos) lido.chave: lido});
      case Error<List<CapituloLidoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Capítulos com leitura, do mais recente para o mais antigo (sem data ficam no fim, na ordem da Bíblia).
  List<CapituloLidoModel> historico(Iterable<CapituloLidoModel> lidos) {
    final lista = lidos.toList();
    lista.sort((a, b) {
      final da = a.lidoEm;
      final db = b.lidoEm;
      if (da != null && db != null) return db.compareTo(da);
      if (da != null) return -1;
      if (db != null) return 1;
      final livro = a.livrId.compareTo(b.livrId);
      return livro != 0 ? livro : a.capiNumero.compareTo(b.capiNumero);
    });
    return lista;
  }

  /// Confirmação de [alternarCapitulo]: [lido] é o progresso devolvido (nulo = desmarcado).
  FeedbackLeitura mensagemCapitulo(CapituloLidoModel? lido) => (lido?.completo ?? false)
      ? (mensagem: 'capituloMarcadoLido', lido: true)
      : (mensagem: 'capituloDesmarcadoLido', lido: false);

  /// Confirmação ao marcar ou desmarcar um versículo. [antes] e [depois] são o progresso do capítulo antes e depois
  /// da marcação: se o capítulo ficou completo agora, avisa que ele foi concluído.
  FeedbackLeitura mensagemVersiculo({required bool lido, CapituloLidoModel? antes, CapituloLidoModel? depois}) {
    if (!lido) return (mensagem: 'versiculoDesmarcadoLido', lido: false);
    final concluiu = (depois?.completo ?? false) && !(antes?.completo ?? false);
    return (mensagem: concluiu ? 'capituloConcluido' : 'versiculoMarcadoLido', lido: true);
  }

  /// Marca o capítulo como lido, ou desmarca se [atual] já estava completo. Devolve o novo progresso do
  /// capítulo, ou nulo quando ele foi desmarcado.
  Future<Result<CapituloLidoModel?>> alternarCapitulo(
    int versaId,
    IndiceCapituloModel capitulo,
    LivroModel? livro,
    CapituloLidoModel? atual,
  ) async {
    final lido = !(atual?.completo ?? false);
    final result = await bibliaLeituraRepository.marcarCapitulo(
      versaId,
      capitulo.livrId,
      capitulo.capiNumero,
      lido: lido,
    );
    switch (result) {
      case Ok<int>(value: final total):
        if (!lido) return const Result.ok(null);
        return Result.ok(
          CapituloLidoModel(
            livrId: capitulo.livrId,
            livrNome: livro?.livrNome ?? capitulo.livrNome,
            livrAbrev: livro?.livrAbrev ?? '',
            capiNumero: capitulo.capiNumero,
            versTotal: total,
            versLidos: total,
            lidoEm: DateTime.now(),
          ),
        );
      case Error<int>(error: final error):
        return Result.error(error);
    }
  }

  /// Progresso de leitura do livro a partir dos [capitulos] do índice e do progresso de cada um ([lidoDe]):
  /// capítulos completos, capítulos começados (com parte dos versículos lidos) e a fração de versículos lidos,
  /// que avança mesmo quando nenhum capítulo está completo.
  ProgressoLivro progressoLivro(
    List<IndiceCapituloModel> capitulos,
    CapituloLidoModel? Function(int capiNumero) lidoDe,
  ) {
    var completos = 0;
    var emAndamento = 0;
    var versLidos = 0;
    var versTotal = 0;
    for (final capitulo in capitulos) {
      versTotal += capitulo.versTotal;
      final lido = lidoDe(capitulo.capiNumero);
      if (lido == null || lido.versLidos <= 0) continue;
      versLidos += lido.versLidos.clamp(0, capitulo.versTotal);
      if (lido.completo) {
        completos++;
      } else {
        emAndamento++;
      }
    }
    return (
      completos: completos,
      emAndamento: emAndamento,
      total: capitulos.length,
      fracao: versTotal == 0 ? 0.0 : versLidos / versTotal,
    );
  }

  /// Reações do usuário aos versículos do capítulo, indexadas por `versId`.
  Future<Result<Map<int, VersiculoReacaoModel>>> reacoesCapitulo(int versaId, CapituloRef ref) async {
    final result = await bibliaLeituraRepository.reacoesCapitulo(versaId, ref.livrId, ref.capiNumero);
    switch (result) {
      case Ok<List<VersiculoReacaoModel>>(value: final reacoes):
        return Result.ok({for (final reacao in reacoes) reacao.versId: reacao});
      case Error<List<VersiculoReacaoModel>>(error: final error):
        return Result.error(error);
    }
  }

  /// Progresso do capítulo calculado a partir das [reacoes] dos versículos; nulo se nenhum versículo está lido.
  CapituloLidoModel? progressoCapitulo(
    IndiceCapituloModel capitulo,
    LivroModel? livro,
    Map<int, VersiculoReacaoModel> reacoes,
  ) {
    final lidos = reacoes.values.where((r) => r.vreaLido).length;
    if (lidos == 0) return null;
    return CapituloLidoModel(
      livrId: capitulo.livrId,
      livrNome: livro?.livrNome ?? capitulo.livrNome,
      livrAbrev: livro?.livrAbrev ?? '',
      capiNumero: capitulo.capiNumero,
      versTotal: capitulo.versTotal,
      versLidos: lidos,
      lidoEm: DateTime.now(),
    );
  }

  /// Todos os capítulos da versão na ordem da Bíblia, passando de um livro para o outro: são as páginas da
  /// leitura (uma por capítulo). [livros] define a ordem dos livros; só entram capítulos do [indice].
  List<CapituloRef> sequencia(Map<int, List<IndiceCapituloModel>> indice, List<LivroModel> livros) => [
    for (final livro in livros)
      for (final capitulo in indice[livro.livrId] ?? const <IndiceCapituloModel>[])
        (livrId: capitulo.livrId, capiNumero: capitulo.capiNumero),
  ];

  /// Capítulo vizinho de [atual] na ordem da Bíblia ([passo] -1 anterior, 1 próximo), passando de um livro para
  /// o outro; nulo no início ou no fim. [livros] define a ordem dos livros.
  CapituloRef? vizinho(
    Map<int, List<IndiceCapituloModel>> indice,
    List<LivroModel> livros,
    CapituloRef atual,
    int passo,
  ) {
    final ordem = sequencia(indice, livros);
    final posicao = ordem.indexOf(atual);
    if (posicao < 0) return null;
    final destino = posicao + passo;
    return destino >= 0 && destino < ordem.length ? ordem[destino] : null;
  }
}
