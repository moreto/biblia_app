import 'dart:async';

import 'package:app/config/command.dart';
import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/anotacao_leitura.dart';
import 'package:app/config/marca_texto.dart';
import 'package:app/config/narracao_voz.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart' show HighlightColor;
import 'package:flutter/material.dart';

import '../../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../../data/model/biblia/indice_capitulo_model.dart';
import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/testamento_model.dart';
import '../../../../data/model/biblia/versao_model.dart';
import '../../../../data/model/biblia/versiculo_indicacao_model.dart';
import '../../../../data/model/biblia/versiculo_indicacao_usuario_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../../../../data/model/usuario/usuario_resumo_model.dart';
import '../../../../data/model/versiculo/versiculo_reacao_model.dart';
import '../../../dashboard/widgets/versiculo_reacao/use_case/versiculo_reacao_usecase.dart';
import '../../../dicionario/use_case/dicionario_usecase.dart';
import '../use_case/biblia_leitura_usecase.dart';
import '../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import '../versiculo_indicacao/use_case/versiculo_indicacao_usuario_usecase.dart';

/// Estado da leitura da Bíblia.
///
/// Ao ser criado executa [carregarCommand]: versões, testamentos e livros e, para a versão escolhida (a primeira),
/// o índice de capítulos e o progresso de leitura do usuário. A partir daí:
/// - [versaoCommand] troca a versão e recarrega índice, progresso e o capítulo aberto;
/// - [selecionarTestamento] filtra os livros do índice (nulo = todos);
/// - [abrirCapituloCommand] carrega os versículos de um capítulo e as reações do usuário a eles;
///   [fecharCapitulo] volta ao índice;
/// - [marcarLidoCommand] marca o capítulo aberto como lido (ou desmarca, se já estava completo);
/// - [marcarVersiculoCommand] marca um versículo como lido (ou desmarca), mantendo o comentário da reação;
/// - [destacarVersiculo] marca (ou desmarca) a linha tocada como indicativo de onde o usuário está lendo; é só
///   visual, não grava nada, e some ao trocar de capítulo;
/// - [estadoIndicacao] diz se o usuário indicou o versículo e se comentou, pelas indicações dele no capítulo
///   (carregadas ao abrir o capítulo e atualizadas ao indicar ou remover);
/// - depois de marcar ou desmarcar (capítulo ou versículo), [feedback] guarda a chave da mensagem de confirmação,
///   lida uma única vez pela view com [consumirFeedback];
/// - [indicacoesCommand], [indicarCommand] e [removerIndicacaoCommand] tratam a indicação do versículo selecionado;
/// - [indicados] são os usuários que recebem a indicação do usuário, carregados com ela; [buscarUsuarios] procura
///   destinatários, [adicionarIndicadoCommand] inclui e [removerIndicadoCommand] remove.
///
/// Com [destino] (ex.: versículo aberto a partir de um renomado), a leitura carrega na versão do destino, abre o
/// capítulo direto e destaca o versículo; [versiculoAlvo] indica à view para onde rolar (lido uma vez com
/// [consumirVersiculoAlvo]).
class BibliaLeituraViewmodel extends ChangeNotifier {
  BibliaLeituraViewmodel({
    required this.bibliaLeituraUseCase,
    required this.versiculoIndicacaoUseCase,
    required this.versiculoReacaoUseCase,
    required this.versiculoIndicacaoUsuarioUseCase,
    this.destino,
  }) {
    Log.print(super.runtimeType);
    carregarCommand.execute();
  }

  /// A tela de leitura está à vista: aplica a orientação e o brilho da leitura (também ao voltar de outra tela).
  Future<void> entrarNaLeitura() => bibliaLeituraUseCase.aplicarAjustesLeitura();

  /// A tela de leitura saiu (voltar, home ou uma tela que não é dela): orientação e brilho voltam aos do sistema.
  /// Sempre solta, sem depender de quem aplicou: o GoRouter pode recriar o viewmodel ao reconstruir a rota.
  Future<void> sairDaLeitura() => bibliaLeituraUseCase.soltarAjustesLeitura();

  final VersiculoReacaoUseCase versiculoReacaoUseCase;

  /// Onde a leitura abre direto; nulo abre no índice.
  final LeituraDestino? destino;

  /// A tela foi aberta direto num capítulo: voltar sai da tela em vez de ir ao índice.
  bool get abertaPorDestino => destino != null;

  /// Há usuário logado. Sem login a leitura é pública: sem progresso, marcações, histórico e indicações.
  bool get logado => bibliaLeituraUseCase.logado;

  /// Multiplicador da fonte dos versículos (opções de leitura).
  double get escalaFonte => bibliaLeituraUseCase.escalaFonte;

  void setEscalaFonte(double escala) {
    bibliaLeituraUseCase.salvarEscalaFonte(escala);
    notifyListeners();
  }

  /// Tema só da leitura (Configurações de leitura); [TemaApp.sistema] usa o do app.
  /// A narração está disponível (há voz no aparelho).
  bool get narracaoDisponivel => bibliaLeituraUseCase.narracaoDisponivel;

  int? _versiculoNarrado;

  /// Versículo sendo lido em voz alta; nulo quando a narração está parada.
  int? get versiculoNarrado => _versiculoNarrado;

  bool get narrando => _versiculoNarrado != null;

  /// Incrementada ao iniciar ou parar a narração: um laço de narração antigo para ao perceber a troca.
  int _narracaoSequencia = 0;

  /// Inicia a narração (do versículo destacado ou do primeiro) ou, se já estiver narrando, para.
  void alternarNarracao() => narrando ? pararNarracao() : unawaited(_narrar());

  /// Narração contínua (opções de leitura): ao terminar o capítulo, passa a página e continua lendo.
  bool get narracaoContinua => bibliaLeituraUseCase.narracaoContinua;

  void setNarracaoContinua(bool continua) {
    bibliaLeituraUseCase.salvarNarracaoContinua(continua);
    notifyListeners();
  }

  /// Próximo capítulo para a view virar a página (narração contínua); lido uma vez com [consumirPassagemAutomatica].
  CapituloRef? _passagemAutomatica;

  CapituloRef? consumirPassagemAutomatica() {
    final destino = _passagemAutomatica;
    _passagemAutomatica = null;
    return destino;
  }

  /// A página foi passada pela narração contínua: ao abrir o capítulo, a narração recomeça nele.
  bool _narrarAoAbrir = false;

  Future<void> _narrar() async {
    final versiculos = _versiculos;
    if (versiculos == null) return;
    final sequencia = ++_narracaoSequencia;
    var completou = true;
    for (final versiculo in BibliaLeituraUseCase.versiculosANarrar(versiculos, _versiculoDestacado)) {
      if (sequencia != _narracaoSequencia) return;
      _versiculoNarrado = versiculo.versId;
      notifyListeners();
      final falou = await bibliaLeituraUseCase.narrar(versiculo.versTexto);
      if (!falou) {
        completou = false;
        break;
      }
    }
    if (sequencia != _narracaoSequencia) return;
    _versiculoNarrado = null;
    final proximo = this.proximo;
    if (completou && narracaoContinua && proximo != null) {
      _narrarAoAbrir = true;
      _passagemAutomatica = proximo;
    }
    notifyListeners();
  }

  /// Vozes em português do aparelho para o seletor das opções de leitura.
  late final Command0<List<VozNarracao>> vozesCommand = Command0(() async {
    return Result.ok(await bibliaLeituraUseCase.vozesNarracao());
  });

  List<VozNarracao> get vozes => switch (vozesCommand.result) {
    Ok(value: final vozes) => vozes,
    _ => const [],
  };

  /// Voz usada na narração (a escolhida ou a melhor).
  VozNarracao? get vozNarracao => bibliaLeituraUseCase.vozEscolhida(vozes);

  void setVozNarracao(VozNarracao voz) {
    bibliaLeituraUseCase.salvarVozNarracao(voz);
    notifyListeners();
    ouvirExemplo();
  }

  double get velocidadeNarracao => bibliaLeituraUseCase.velocidadeNarracao;

  void setVelocidadeNarracao(double velocidade) {
    bibliaLeituraUseCase.salvarVelocidadeNarracao(velocidade);
    notifyListeners();
  }

  /// Narra só o trecho selecionado (interrompe a narração do capítulo, se houver).
  void ouvirTrecho(String texto) {
    pararNarracao();
    unawaited(bibliaLeituraUseCase.narrar(texto));
  }

  /// Fala a frase de exemplo na [voz] (sem escolhê-la), na velocidade atual.
  void ouvirVoz(VozNarracao voz) {
    pararNarracao();
    unawaited(bibliaLeituraUseCase.narrar(BibliaLeituraUseCase.exemploNarracao, voz: voz));
  }

  /// Fala a frase de exemplo com a voz e a velocidade atuais (para a narração do capítulo, se estiver lendo).
  void ouvirExemplo() {
    pararNarracao();
    unawaited(bibliaLeituraUseCase.narrar(BibliaLeituraUseCase.exemploNarracao));
  }

  /// Para a narração (também ao trocar ou fechar o capítulo e ao sair da tela).
  void pararNarracao() {
    _narrarAoAbrir = false;
    _passagemAutomatica = null;
    _interromperNarracao();
  }

  /// Para a narração ao sair da tela, sem avisar os ouvintes (a tela está sendo desmontada).
  void pararNarracaoAoSair() {
    _narrarAoAbrir = false;
    _passagemAutomatica = null;
    _narracaoSequencia++;
    _versiculoNarrado = null;
    unawaited(bibliaLeituraUseCase.pararNarracao());
  }

  /// Interrompe a fala sem cancelar a narração contínua (troca de capítulo).
  void _interromperNarracao() {
    _narracaoSequencia++;
    final narrava = narrando;
    _versiculoNarrado = null;
    unawaited(bibliaLeituraUseCase.pararNarracao());
    if (narrava) notifyListeners();
  }

  /// Consulta no dicionário da palavra tocada (toque longo) e das remissões abertas no sheet da palavra.
  late final Command1<DicionarioConsulta, String> consultarPalavraCommand = Command1(
    bibliaLeituraUseCase.consultarPalavra,
  );

  /// Palavra do versículo na posição tocada; nula se não houver.
  String? palavraEm(String texto, int offset) => BibliaLeituraUseCase.palavraEm(texto, offset);

  /// Início e fim da palavra na posição tocada, para marcá-la no texto; nulo se não houver.
  ({int inicio, int fim})? intervaloPalavraEm(String texto, int offset) =>
      BibliaLeituraUseCase.intervaloPalavraEm(texto, offset);

  /// O que fazer com o capítulo ao passar para o próximo (opções de leitura).
  MarcarAoPassar get marcarAoPassar => bibliaLeituraUseCase.marcarAoPassar;

  void setMarcarAoPassar(MarcarAoPassar valor) {
    bibliaLeituraUseCase.salvarMarcarAoPassar(valor);
    notifyListeners();
  }

  /// O que fazer com o capítulo [de] ao passar para [para].
  MarcarAoPassar acaoAoPassar(CapituloRef de, CapituloRef para) =>
      bibliaLeituraUseCase.acaoAoPassar(sequencia, de, para, lidoDe(de.livrId, de.capiNumero));

  /// Setas anterior/próximo na navegação flutuante (opções de leitura).
  bool get mostrarSetas => bibliaLeituraUseCase.mostrarSetas;

  void setMostrarSetas(bool mostrar) {
    bibliaLeituraUseCase.salvarMostrarSetas(mostrar);
    notifyListeners();
  }

  TemaApp get tema => bibliaLeituraUseCase.tema;

  /// Cor do marca-texto (escolhida nas Configurações de leitura): "Marcar texto" no sheet do trecho usa ela.
  HighlightColor get corMarcaTexto => bibliaLeituraUseCase.corMarcaTexto;

  void setCorMarcaTexto(HighlightColor cor) {
    bibliaLeituraUseCase.salvarCorMarcaTexto(cor);
    notifyListeners();
  }

  void setTema(TemaApp tema) {
    bibliaLeituraUseCase.salvarTema(tema);
    notifyListeners();
  }

  double? _brilho;

  /// Brilho da tela (0 a 1) no ajuste das opções de leitura; nulo enquanto não lido ou sem suporte.
  double? get brilho => _brilho;

  /// Posiciona o ajuste: o brilho guardado da leitura ou, sem ele, o atual (nulo sem suporte a brilho).
  Future<void> carregarBrilho() async {
    if (_brilho != null) return;
    final atual = await bibliaLeituraUseCase.brilhoAtual();
    _brilho = atual == null ? null : bibliaLeituraUseCase.brilhoLeitura ?? atual;
    notifyListeners();
  }

  /// Guarda e aplica o brilho, que passa a valer sempre que a leitura abrir.
  void setBrilho(double valor) {
    _brilho = valor;
    notifyListeners();
    unawaited(bibliaLeituraUseCase.salvarBrilho(valor));
  }

  /// Volta as configurações da leitura ao padrão ([BibliaLeituraUseCase.restaurarPadrao]) e relê o brilho, já
  /// devolvido ao do sistema.
  Future<void> restaurarPadrao() async {
    pararNarracao();
    await bibliaLeituraUseCase.restaurarPadrao();
    _brilho = await bibliaLeituraUseCase.brilhoAtual();
    notifyListeners();
  }

  int? _versiculoAlvo;

  /// Versículo do [destino] para onde a view deve rolar; nulo quando não há rolagem pendente.
  int? get versiculoAlvo => _versiculoAlvo;

  /// Devolve [versiculoAlvo] e o limpa, para a rolagem acontecer uma única vez.
  int? consumirVersiculoAlvo() {
    final alvo = _versiculoAlvo;
    _versiculoAlvo = null;
    return alvo;
  }

  final VersiculoIndicacaoUsuarioUseCase versiculoIndicacaoUsuarioUseCase;

  late final Command1<VersiculoReacaoModel, VersiculoTextoModel> marcarVersiculoCommand = Command1(_marcarVersiculo);

  /// Reações do usuário aos versículos do capítulo aberto, por `versId`.
  Map<int, VersiculoReacaoModel> _reacoes = const {};

  /// O versículo está marcado como lido pelo usuário.
  bool versiculoLido(int versId) => _reacoes[versId]?.vreaLido ?? false;

  /// Indicações do usuário aos versículos do capítulo aberto, por `versId`.
  Map<int, VersiculoIndicacaoModel> _indicacoesCapitulo = const {};

  /// Estado da indicação do usuário ao versículo (não indicado, indicado ou com comentário).
  EstadoIndicacao estadoIndicacao(int versId) => versiculoIndicacaoUseCase.estado(_indicacoesCapitulo[versId]);

  int? _versiculoDestacado;

  /// Versículo tocado como indicativo de leitura; nulo quando nenhum.
  int? get versiculoDestacado => _versiculoDestacado;

  /// Destaca a linha do versículo [versId] como indicativo de leitura; tocar de novo remove o destaque.
  void destacarVersiculo(int versId) {
    _versiculoDestacado = _versiculoDestacado == versId ? null : versId;
    notifyListeners();
  }

  /// Versículo cuja marcação está sendo gravada; nulo quando nenhum.
  int? _versiculoGravando;
  int? get versiculoGravando => _versiculoGravando;

  /// Confirmação da última marcação (capítulo ou versículo); nula se não há mensagem pendente.
  FeedbackLeitura? _feedback;
  FeedbackLeitura? get feedback => _feedback;

  /// Devolve a confirmação pendente de [feedback] e a limpa, para ser mostrada uma única vez.
  FeedbackLeitura? consumirFeedback() {
    final mensagem = _feedback;
    _feedback = null;
    return mensagem;
  }

  final BibliaLeituraUseCase bibliaLeituraUseCase;
  final VersiculoIndicacaoUseCase versiculoIndicacaoUseCase;

  late final Command0<void> carregarCommand = Command0(_carregar);
  late final Command1<void, VersaoModel> versaoCommand = Command1(_trocarVersao);
  late final Command1<List<VersiculoTextoModel>, CapituloRef> abrirCapituloCommand = Command1(_abrirCapitulo);
  late final Command0<CapituloLidoModel?> marcarLidoCommand = Command0(() => _alternarCapitulo(_capitulo));

  /// Marca o capítulo que ficou para trás ao passar a página (ver [acaoAoPassar]).
  late final Command1<CapituloLidoModel?, CapituloRef> marcarAoPassarCommand = Command1(_alternarCapitulo);
  late final Command1<IndicacoesVersiculo, VersiculoTextoModel> indicacoesCommand = Command1(_carregarIndicacoes);

  /// Argumento: comentário opcional da indicação.
  late final Command1<VersiculoIndicacaoModel, String?> indicarCommand = Command1(_indicar);
  late final Command0<void> removerIndicacaoCommand = Command0(_removerIndicacao);
  late final Command1<VersiculoIndicacaoUsuarioModel, UsuarioResumoModel> adicionarIndicadoCommand = Command1(
    _adicionarIndicado,
  );
  late final Command1<void, VersiculoIndicacaoUsuarioModel> removerIndicadoCommand = Command1(_removerIndicado);

  List<VersiculoIndicacaoUsuarioModel> _indicados = const [];

  /// Usuários que recebem a indicação do usuário ao [versiculoSelecionado].
  List<VersiculoIndicacaoUsuarioModel> get indicados => _indicados;

  List<UsuarioResumoModel> _usuariosEncontrados = const [];

  /// Resultado da última [buscarUsuarios], sem quem já está em [indicados].
  List<UsuarioResumoModel> get usuariosEncontrados => _usuariosEncontrados;

  bool _buscandoUsuarios = false;
  bool get buscandoUsuarios => _buscandoUsuarios;

  /// Chave de tradução do erro da última busca de usuários; nula se não houve erro.
  String? _erroBuscaUsuarios;
  String? get erroBuscaUsuarios => _erroBuscaUsuarios;

  /// Numera as buscas para descartar respostas de buscas antigas (o usuário continua digitando).
  int _buscaSequencia = 0;

  /// Nome mostrado de um usuário (nome completo ou, sem ele, nome de usuário).
  String? nomeUsuario({String? udetNome, String? udetUsuario}) =>
      versiculoIndicacaoUsuarioUseCase.nomeExibicao(udetNome: udetNome, udetUsuario: udetUsuario);

  /// Tamanho mínimo do texto para buscar usuários.
  int get buscaUsuarioMinimo => VersiculoIndicacaoUsuarioUseCase.buscaMinimo;

  List<VersaoModel> _versoes = const [];
  List<VersaoModel> get versoes => _versoes;

  VersaoModel? _versao;
  VersaoModel? get versao => _versao;

  List<TestamentoModel> _testamentos = const [];
  List<TestamentoModel> get testamentos => _testamentos;

  int? _testamentoId;

  /// Testamento do filtro; nulo mostra todos os livros.
  int? get testamentoId => _testamentoId;

  List<LivroModel> _livros = const [];

  /// Capítulos da versão por livro; nulo até o primeiro carregamento concluir (ou se ele falhar).
  Map<int, List<IndiceCapituloModel>>? _indice;
  Map<int, List<IndiceCapituloModel>>? get indice => _indice;

  Map<String, CapituloLidoModel> _lidos = const {};

  CapituloRef? _capitulo;

  /// Capítulo aberto para leitura; nulo mostra o índice.
  CapituloRef? get capitulo => _capitulo;

  List<VersiculoTextoModel>? _versiculos;

  /// Versículos do [capitulo]; nulo enquanto carrega ou se o carregamento falhou.
  List<VersiculoTextoModel>? get versiculos => _versiculos;

  VersiculoTextoModel? _versiculoSelecionado;
  VersiculoTextoModel? get versiculoSelecionado => _versiculoSelecionado;

  IndicacoesVersiculo? _indicacoes;

  /// Indicações do [versiculoSelecionado]; nulas enquanto carregam ou se a consulta falhou.
  IndicacoesVersiculo? get indicacoes => _indicacoes;

  /// Livros do índice da versão, filtrados pelo [testamentoId], na ordem da Bíblia.
  List<LivroModel> get livros {
    final indice = _indice ?? const {};
    return _livros
        .where((livro) => indice.containsKey(livro.livrId))
        .where((livro) => _testamentoId == null || livro.testId == _testamentoId)
        .toList(growable: false);
  }

  List<IndiceCapituloModel> capitulosDo(int livrId) => _indice?[livrId] ?? const [];

  LivroModel? livroDe(int livrId) {
    for (final livro in _livros) {
      if (livro.livrId == livrId) return livro;
    }
    return null;
  }

  /// Progresso do capítulo; nulo se o usuário não leu nenhum versículo dele.
  CapituloLidoModel? lidoDe(int livrId, int capiNumero) => _lidos[CapituloLidoModel.chaveDe(livrId, capiNumero)];

  /// Quantos capítulos do livro estão completos.
  int capitulosLidosDo(int livrId) => progressoDo(livrId).completos;

  /// Progresso do livro no índice (capítulos completos, começados e fração de versículos lidos).
  ProgressoLivro progressoDo(int livrId) =>
      bibliaLeituraUseCase.progressoLivro(capitulosDo(livrId), (capiNumero) => lidoDe(livrId, capiNumero));

  /// Histórico de leitura (do mais recente para o mais antigo).
  List<CapituloLidoModel> get historico => bibliaLeituraUseCase.historico(_lidos.values);

  CapituloLidoModel? get lidoAtual => switch (_capitulo) {
    final ref? => lidoDe(ref.livrId, ref.capiNumero),
    null => null,
  };

  /// Capítulos da versão em ordem: as páginas da leitura (uma por capítulo).
  List<CapituloRef> _sequencia = const [];
  List<CapituloRef> get sequencia => _sequencia;

  /// Texto dos capítulos já carregados na versão atual, para mostrar as páginas vizinhas enquanto a página vira e
  /// abrir o capítulo sem esperar a API de novo. Limpo ao trocar de versão.
  final Map<CapituloRef, List<VersiculoTextoModel>> _textos = {};
  final Set<CapituloRef> _carregandoTextos = {};

  /// Texto de [ref]: o do capítulo aberto ou o do cache; nulo enquanto não foi carregado.
  List<VersiculoTextoModel>? textoDe(CapituloRef ref) => ref == _capitulo ? _versiculos ?? _textos[ref] : _textos[ref];

  /// Carrega só o texto de [ref] (sem reações nem indicações), para a página vizinha já estar pronta quando a
  /// página virar. Não faz nada se já está no cache ou carregando; falha só vai para o log.
  /// Marcações do marca-texto por capítulo (da versão atual).
  final Map<CapituloRef, List<MarcaTexto>> _marcas = {};

  bool get marcaTextoDisponivel => bibliaLeituraUseCase.marcaTextoDisponivel;

  /// Marcações do capítulo [ref]; vazia enquanto não carregadas.
  List<MarcaTexto> marcasDe(CapituloRef ref) => _marcas[ref] ?? const [];

  Future<void> _carregarMarcas(CapituloRef ref) async {
    final versao = _versao;
    if (versao == null || _marcas.containsKey(ref) || !marcaTextoDisponivel) return;
    final marcas = await bibliaLeituraUseCase.marcasDoCapitulo(versao.versaId, ref);
    if (versao.versaId != _versao?.versaId) return;
    _marcas[ref] = marcas;
    notifyListeners();
  }

  /// Trecho marcado sob a posição [offset] do versículo [indice] do capítulo aberto; nulo se ali não há marcação.
  (({int indice, int offset}), ({int indice, int offset}))? trechoDaMarcaEm(int indice, int offset) {
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (ref == null || versiculos == null) return null;
    return BibliaLeituraUseCase.trechoDaMarcaEm(marcasDe(ref), versiculos, indice, offset);
  }

  /// O trecho selecionado no capítulo aberto já tem marcação.
  bool trechoMarcado(({int indice, int offset}) inicio, ({int indice, int offset}) fim) {
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (ref == null || versiculos == null) return false;
    return BibliaLeituraUseCase.trechoMarcado(marcasDe(ref), versiculos, inicio, fim);
  }

  /// Cor da marcação do trecho (a primeira que o toca); sem marcação, a do marca-texto das configurações.
  HighlightColor corDaMarcaDoTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim) {
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (ref == null || versiculos == null) return corMarcaTexto;
    return BibliaLeituraUseCase.corDaMarcaNoTrecho(marcasDe(ref), versiculos, inicio, fim) ?? corMarcaTexto;
  }

  /// Pinta o trecho selecionado do capítulo aberto com [cor] e salva.
  void marcarTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim, HighlightColor cor) =>
      _alterarMarcas((marcas, versiculos) => BibliaLeituraUseCase.marcar(marcas, versiculos, inicio, fim, cor));

  /// Apaga a marcação do trecho selecionado do capítulo aberto e salva.
  void desmarcarTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim) =>
      _alterarMarcas((marcas, versiculos) => BibliaLeituraUseCase.desmarcar(marcas, versiculos, inicio, fim));

  void _alterarMarcas(List<MarcaTexto> Function(List<MarcaTexto>, List<VersiculoTextoModel>) alterar) {
    final versao = _versao;
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (versao == null || ref == null || versiculos == null) return;
    final marcas = alterar(marcasDe(ref), versiculos);
    _marcas[ref] = marcas;
    notifyListeners();
    unawaited(bibliaLeituraUseCase.salvarMarcas(versao.versaId, ref, marcas));
  }

  /// Anotações por capítulo (da versão atual).
  final Map<CapituloRef, List<AnotacaoTrecho>> _anotacoes = {};

  List<TagLeitura> _tags = const [];
  bool _tagsCarregadas = false;

  bool get anotacaoDisponivel => bibliaLeituraUseCase.anotacaoDisponivel;

  bool get compartilhamentoDisponivel => bibliaLeituraUseCase.compartilhamentoDisponivel;

  /// Tags do usuário, em ordem alfabética.
  List<TagLeitura> get tags => _tags;

  /// Anotações do capítulo [ref]; vazia enquanto não carregadas.
  List<AnotacaoTrecho> anotacoesDe(CapituloRef ref) => _anotacoes[ref] ?? const [];

  Future<void> _carregarAnotacoes(CapituloRef ref) async {
    final versao = _versao;
    if (versao == null || _anotacoes.containsKey(ref) || !anotacaoDisponivel) return;
    unawaited(carregarTags());
    final anotacoes = await bibliaLeituraUseCase.anotacoesDoCapitulo(versao.versaId, ref);
    if (versao.versaId != _versao?.versaId) return;
    _anotacoes[ref] = anotacoes;
    notifyListeners();
  }

  /// Carrega as tags (uma vez só).
  Future<void> carregarTags() async {
    if (_tagsCarregadas || !anotacaoDisponivel) return;
    _tagsCarregadas = true;
    _tags = await bibliaLeituraUseCase.tagsLeitura();
    notifyListeners();
  }

  /// Partes do versículo [indice] do capítulo [ref] que têm anotação, com a cor da anotação (nula sem tag).
  List<({int inicio, int fim, CorTag? cor})> trechosAnotados(CapituloRef ref, int indice) {
    final versiculos = textoDe(ref);
    final anotacoes = anotacoesDe(ref);
    if (versiculos == null || anotacoes.isEmpty || indice >= versiculos.length) return const [];
    return [
      for (final t in BibliaLeituraUseCase.trechosAnotados(anotacoes, versiculos, indice))
        (inicio: t.inicio, fim: t.fim, cor: corDaAnotacao(t.anotacao)),
    ];
  }

  /// Cor da anotação [a]: a da primeira tag dela; nula sem tag.
  CorTag? corDaAnotacao(AnotacaoTrecho a) => BibliaLeituraUseCase.corDaAnotacao(a, _tags);

  /// Cor sugerida para a próxima tag.
  CorTag get corSugerida => BibliaLeituraUseCase.proximaCor(_tags);

  /// Anotação feita exatamente no trecho selecionado do capítulo aberto; nula se não houver.
  AnotacaoTrecho? anotacaoDoTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim) {
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (ref == null || versiculos == null) return null;
    return BibliaLeituraUseCase.anotacaoDoTrecho(anotacoesDe(ref), versiculos, inicio, fim);
  }

  /// Trecho da anotação sob a posição [offset] do versículo [indice] do capítulo aberto; nulo se ali não há
  /// anotação.
  (({int indice, int offset}), ({int indice, int offset}))? trechoDaAnotacaoEm(int indice, int offset) {
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (ref == null || versiculos == null) return null;
    final anotacao = BibliaLeituraUseCase.anotacaoEm(anotacoesDe(ref), versiculos, indice, offset);
    return anotacao == null ? null : BibliaLeituraUseCase.posicaoDaAnotacao(anotacao, versiculos);
  }

  /// Tags (ids) do trecho selecionado do capítulo aberto, na ordem em que foram marcadas.
  List<String> tagsDoTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim) =>
      anotacaoDoTrecho(inicio, fim)?.tags ?? const [];

  /// Marca a tag [tagId] no trecho selecionado (ou desmarca, se já estava), mantendo o texto da anotação. A
  /// primeira tag dá a cor do trecho.
  void alternarTagTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim, String tagId) {
    final atuais = tagsDoTrecho(inicio, fim);
    _gravarTrecho(
      inicio,
      fim,
      tags: atuais.contains(tagId)
          ? [
              for (final t in atuais)
                if (t != tagId) t,
            ]
          : [...atuais, tagId],
    );
  }

  /// Grava o texto da anotação do trecho selecionado, mantendo as tags dele; texto vazio sem tags apaga o trecho.
  void salvarAnotacao(({int indice, int offset}) inicio, ({int indice, int offset}) fim, {required String texto}) =>
      _gravarTrecho(inicio, fim, texto: texto);

  /// Apaga o texto da anotação do trecho selecionado (as tags dele ficam).
  void excluirAnotacao(({int indice, int offset}) inicio, ({int indice, int offset}) fim) =>
      _gravarTrecho(inicio, fim, texto: '');

  /// Grava texto e/ou tags do trecho selecionado (o que não vier, fica como estava).
  void _gravarTrecho(
    ({int indice, int offset}) inicio,
    ({int indice, int offset}) fim, {
    String? texto,
    List<String>? tags,
  }) {
    final atual = anotacaoDoTrecho(inicio, fim);
    _alterarAnotacoes(
      (anotacoes, versiculos) => BibliaLeituraUseCase.comAnotacao(
        anotacoes,
        versiculos,
        inicio,
        fim,
        id: atual?.id,
        texto: texto ?? atual?.texto ?? '',
        tags: tags ?? atual?.tags ?? const [],
        agora: DateTime.now(),
      ),
    );
  }

  void _alterarAnotacoes(List<AnotacaoTrecho> Function(List<AnotacaoTrecho>, List<VersiculoTextoModel>) alterar) {
    final versao = _versao;
    final ref = _capitulo;
    final versiculos = _versiculos;
    if (versao == null || ref == null || versiculos == null) return;
    final anotacoes = alterar(anotacoesDe(ref), versiculos);
    _anotacoes[ref] = anotacoes;
    notifyListeners();
    unawaited(bibliaLeituraUseCase.salvarAnotacoes(versao.versaId, ref, anotacoes));
  }

  /// Chave do erro do nome de tag [nome]; nulo se serve. [exceto] é a tag sendo renomeada.
  String? validarTag(String nome, {String? exceto}) => BibliaLeituraUseCase.validarTag(nome, _tags, exceto: exceto);

  /// Cria a tag [nome] (já validado com [validarTag]) na [cor] (sem ela, a [corSugerida]) e a devolve.
  TagLeitura criarTag(String nome, {CorTag? cor}) {
    final tag = (id: BibliaLeituraUseCase.novoId(DateTime.now()), nome: nome.trim(), cor: cor ?? corSugerida);
    _salvarTags([..._tags, tag]);
    return tag;
  }

  /// Renomeia a tag [id] para [nome] (já validado com [validarTag]).
  void renomearTag(String id, String nome) =>
      _salvarTags([for (final t in _tags) t.id == id ? (id: id, nome: nome.trim(), cor: t.cor) : t]);

  /// Troca a cor da tag [id].
  void mudarCorTag(String id, CorTag cor) =>
      _salvarTags([for (final t in _tags) t.id == id ? (id: id, nome: t.nome, cor: cor) : t]);

  /// Apaga a tag [id] e a tira das anotações carregadas (nas outras, a tag apagada é ignorada).
  void excluirTag(String id) {
    _salvarTags([
      for (final t in _tags)
        if (t.id != id) t,
    ]);
    final versao = _versao;
    if (versao == null) return;
    for (final MapEntry(key: ref, value: anotacoes) in _anotacoes.entries.toList()) {
      if (!anotacoes.any((a) => a.tags.contains(id))) continue;
      final novas = BibliaLeituraUseCase.semTag(anotacoes, id);
      _anotacoes[ref] = novas;
      unawaited(bibliaLeituraUseCase.salvarAnotacoes(versao.versaId, ref, novas));
    }
    notifyListeners();
  }

  void _salvarTags(List<TagLeitura> tags) {
    _tags = BibliaLeituraUseCase.ordenarTags(tags);
    notifyListeners();
    unawaited(bibliaLeituraUseCase.salvarTags(_tags));
  }

  /// Compartilha o trecho com a referência e a [mensagem] opcional.
  Future<void> compartilharTrecho(String texto, String referencia, {String? mensagem}) =>
      bibliaLeituraUseCase.compartilhar(BibliaLeituraUseCase.textoCompartilhado(texto, referencia, mensagem: mensagem));

  Future<void> precarregar(CapituloRef ref) async {
    unawaited(_carregarMarcas(ref));
    unawaited(_carregarAnotacoes(ref));
    final versao = _versao;
    if (versao == null || _textos.containsKey(ref) || !_carregandoTextos.add(ref)) return;
    final result = await bibliaLeituraUseCase.capitulo(versao.versaId, ref);
    _carregandoTextos.remove(ref);
    // Ignora se a versão mudou enquanto carregava.
    if (versao.versaId != _versao?.versaId) return;
    switch (result) {
      case Ok<List<VersiculoTextoModel>>(value: final versiculos):
        _textos[ref] = versiculos;
        notifyListeners();
      case Error<List<VersiculoTextoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  CapituloRef? get anterior => _vizinho(-1);
  CapituloRef? get proximo => _vizinho(1);

  CapituloRef? _vizinho(int passo) {
    final ref = _capitulo;
    final indice = _indice;
    if (ref == null || indice == null) return null;
    return bibliaLeituraUseCase.vizinho(indice, _livros, ref, passo);
  }

  void selecionarTestamento(int? testId) {
    if (_testamentoId == testId) return;
    _testamentoId = testId;
    notifyListeners();
  }

  void fecharCapitulo() {
    pararNarracao();
    _capitulo = null;
    _versiculos = null;
    _reacoes = const {};
    _indicacoesCapitulo = const {};
    _versiculoDestacado = null;
    _limparVersiculo();
    notifyListeners();
  }

  void _limparVersiculo() {
    _versiculoSelecionado = null;
    _indicacoes = null;
    _limparIndicados();
  }

  void _limparIndicados() {
    _indicados = const [];
    limparBuscaUsuarios(notificar: false);
  }

  /// Limpa o resultado da busca de usuários (e descarta uma busca em andamento).
  void limparBuscaUsuarios({bool notificar = true}) {
    _buscaSequencia++;
    _usuariosEncontrados = const [];
    _buscandoUsuarios = false;
    _erroBuscaUsuarios = null;
    if (notificar) notifyListeners();
  }

  /// Busca destinatários para a indicação pelo [texto] (nome ou nome de usuário). Só a resposta da busca mais
  /// recente é usada.
  Future<void> buscarUsuarios(String texto) async {
    final sequencia = ++_buscaSequencia;
    _buscandoUsuarios = true;
    _erroBuscaUsuarios = null;
    notifyListeners();

    final result = await versiculoIndicacaoUsuarioUseCase.buscar(texto, _indicados);
    if (sequencia != _buscaSequencia) return;
    switch (result) {
      case Ok<List<UsuarioResumoModel>>(value: final value):
        _usuariosEncontrados = value;
      case Error<List<UsuarioResumoModel>>(error: final error):
        _usuariosEncontrados = const [];
        _erroBuscaUsuarios = versiculoIndicacaoUsuarioUseCase.errorMessage(error);
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    _buscandoUsuarios = false;
    notifyListeners();
  }

  /// Carrega os destinatários da indicação [minha] do versículo [versId]; falha deixa a lista vazia.
  Future<void> _carregarIndicados(int versId, VersiculoIndicacaoModel? minha) async {
    final result = await versiculoIndicacaoUsuarioUseCase.usuarios(minha);
    if (_versiculoSelecionado?.versId != versId) return;
    switch (result) {
      case Ok<List<VersiculoIndicacaoUsuarioModel>>(value: final value):
        _indicados = value;
      case Error<List<VersiculoIndicacaoUsuarioModel>>(error: final error):
        _indicados = const [];
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  Future<Result<VersiculoIndicacaoUsuarioModel>> _adicionarIndicado(UsuarioResumoModel usuario) async {
    final versId = _versiculoSelecionado?.versId;
    final result = await versiculoIndicacaoUsuarioUseCase.adicionar(_indicacoes?.minha, usuario, _indicados);
    switch (result) {
      case Ok<VersiculoIndicacaoUsuarioModel>(value: final indicado):
        if (_versiculoSelecionado?.versId == versId) {
          _indicados = [..._indicados, indicado];
          _usuariosEncontrados = _usuariosEncontrados.where((u) => u.usuaId != usuario.usuaId).toList();
        }
      case Error<VersiculoIndicacaoUsuarioModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _removerIndicado(VersiculoIndicacaoUsuarioModel indicado) async {
    final result = await versiculoIndicacaoUsuarioUseCase.remover(indicado);
    switch (result) {
      case Ok<void>():
        _indicados = _indicados.where((i) => i.viusId != indicado.viusId).toList();
      case Error<void>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _carregar() async {
    notifyListeners();

    final (versoes, testamentos, livros) = await (
      bibliaLeituraUseCase.versoes(),
      bibliaLeituraUseCase.testamentos(),
      bibliaLeituraUseCase.livros(),
    ).wait;

    for (final Result result in [versoes, testamentos, livros]) {
      if (result case Error(error: final error)) {
        Log.print(error.toString(), name: kApp, title: 'Erro');
        notifyListeners();
        return Result.error(error);
      }
    }

    _versoes = (versoes as Ok<List<VersaoModel>>).value;
    _testamentos = (testamentos as Ok<List<TestamentoModel>>).value;
    _livros = (livros as Ok<List<LivroModel>>).value;

    final versao = _versao ?? bibliaLeituraUseCase.versaoDoDestino(_versoes, destino);
    if (versao == null) {
      notifyListeners();
      return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));
    }

    final result = await _carregarVersao(versao);
    if (result is Ok && _capitulo == null) await _abrirDestino();
    notifyListeners();
    return result;
  }

  /// Carrega índice e progresso da [versao]. Falha no progresso não impede a leitura: o índice aparece sem lidos.
  Future<Result<void>> _carregarVersao(VersaoModel versao) async {
    // Sem login não há progresso: nem chama a API (que exigiria o token do usuário).
    final (indice, lidos) = await (
      bibliaLeituraUseCase.indice(versao.versaId),
      logado
          ? bibliaLeituraUseCase.lidos(versao.versaId)
          : Future.value(const Result<Map<String, CapituloLidoModel>>.ok({})),
    ).wait;

    switch (indice) {
      case Ok<Map<int, List<IndiceCapituloModel>>>(value: final value):
        if (_versao?.versaId != versao.versaId) {
          _textos.clear();
          _marcas.clear();
          _anotacoes.clear();
        }
        _versao = versao;
        _indice = value;
        _sequencia = bibliaLeituraUseCase.sequencia(value, _livros);
      case Error<Map<int, List<IndiceCapituloModel>>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
        return Result.error(error);
    }

    switch (lidos) {
      case Ok<Map<String, CapituloLidoModel>>(value: final value):
        _lidos = value;
      case Error<Map<String, CapituloLidoModel>>(error: final error):
        _lidos = const {};
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    return const Result.ok(null);
  }

  /// Abre o capítulo do [destino] (se existir na versão) e destaca o versículo.
  Future<void> _abrirDestino() async {
    final alvo = destino;
    final indice = _indice;
    if (alvo == null || indice == null || !bibliaLeituraUseCase.destinoDisponivel(indice, alvo)) return;

    final result = await _abrirCapitulo(alvo.capitulo);
    if (result case Ok(value: final versiculos)) {
      final versId = bibliaLeituraUseCase.versiculoDoDestino(versiculos, alvo.versNumero);
      _versiculoDestacado = versId;
      _versiculoAlvo = versId;
    }
  }

  Future<Result<void>> _trocarVersao(VersaoModel versao) async {
    if (versao.versaId == _versao?.versaId) return const Result.ok(null);
    notifyListeners();

    final result = await _carregarVersao(versao);
    if (result is Ok) {
      bibliaLeituraUseCase.salvarVersao(versao);
      final ref = _capitulo;
      // O capítulo aberto é recarregado na nova versão; se ela não tem o capítulo, volta ao índice.
      if (ref != null) {
        final existe = capitulosDo(ref.livrId).any((c) => c.capiNumero == ref.capiNumero);
        if (existe) {
          await _abrirCapitulo(ref);
        } else {
          fecharCapitulo();
        }
      }
    }

    notifyListeners();
    return result;
  }

  Future<Result<List<VersiculoTextoModel>>> _abrirCapitulo(CapituloRef ref) async {
    final versao = _versao;
    if (versao == null) {
      return Result.error(HandledException(message: 'nenhumaVersaoDisponivel'));
    }
    if (_capitulo != ref) _interromperNarracao();
    _capitulo = ref;
    // Com o texto no cache (página vizinha já carregada), o capítulo aparece na hora; reações e indicações chegam
    // em seguida.
    _versiculos = _textos[ref];
    unawaited(_carregarMarcas(ref));
    unawaited(_carregarAnotacoes(ref));
    _reacoes = const {};
    _indicacoesCapitulo = const {};
    _versiculoDestacado = null;
    _limparVersiculo();
    notifyListeners();

    // Sem login só o texto: reações e indicações são do usuário.
    final (result, reacoes, indicacoes) = await (
      bibliaLeituraUseCase.capitulo(versao.versaId, ref),
      logado
          ? bibliaLeituraUseCase.reacoesCapitulo(versao.versaId, ref)
          : Future.value(const Result<Map<int, VersiculoReacaoModel>>.ok({})),
      logado
          ? versiculoIndicacaoUseCase.indicacoesCapitulo(versao.versaId, ref.livrId, ref.capiNumero)
          : Future.value(const Result<Map<int, VersiculoIndicacaoModel>>.ok({})),
    ).wait;
    // Ignora a resposta se outro capítulo foi aberto enquanto este carregava.
    final atual = _capitulo == ref;
    switch (result) {
      case Ok<List<VersiculoTextoModel>>(value: final versiculos):
        _textos[ref] = versiculos;
        if (atual) {
          _versiculos = versiculos;
          bibliaLeituraUseCase.salvarUltimoCapitulo(versao.versaId, ref);
          // Narração contínua: o capítulo novo começa a ser lido assim que o texto chega.
          if (_narrarAoAbrir) {
            _narrarAoAbrir = false;
            unawaited(_narrar());
          }
        }
      case Error<List<VersiculoTextoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    // Falha nas reações não impede a leitura: os versículos aparecem sem marcação.
    switch (reacoes) {
      case Ok<Map<int, VersiculoReacaoModel>>(value: final value):
        if (atual) _reacoes = value;
      case Error<Map<int, VersiculoReacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
    // Falha nas indicações também não impede a leitura: os ícones aparecem como não indicados.
    switch (indicacoes) {
      case Ok<Map<int, VersiculoIndicacaoModel>>(value: final value):
        if (atual) _indicacoesCapitulo = value;
      case Error<Map<int, VersiculoIndicacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  /// Recarrega as reações do capítulo aberto (depois de marcar ou desmarcar o capítulo inteiro).
  Future<void> _recarregarReacoes() async {
    final versao = _versao;
    final ref = _capitulo;
    if (versao == null || ref == null) return;
    final result = await bibliaLeituraUseCase.reacoesCapitulo(versao.versaId, ref);
    switch (result) {
      case Ok<Map<int, VersiculoReacaoModel>>(value: final value):
        if (_capitulo == ref) _reacoes = value;
      case Error<Map<int, VersiculoReacaoModel>>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }
  }

  Future<Result<VersiculoReacaoModel>> _marcarVersiculo(VersiculoTextoModel versiculo) async {
    final ref = _capitulo;
    _versiculoGravando = versiculo.versId;
    notifyListeners();

    final result = await versiculoReacaoUseCase.alternarLido(
      versiculo.versId,
      _reacoes[versiculo.versId],
      manterComentario: true,
    );
    switch (result) {
      case Ok<VersiculoReacaoModel>(value: final reacao):
        if (ref != null && _capitulo == ref) {
          _reacoes = {..._reacoes, reacao.versId: reacao};
          final capitulo = capitulosDo(ref.livrId).where((c) => c.capiNumero == ref.capiNumero).firstOrNull;
          final chave = CapituloLidoModel.chaveDe(ref.livrId, ref.capiNumero);
          final antes = _lidos[chave];
          if (capitulo != null) {
            final progresso = bibliaLeituraUseCase.progressoCapitulo(capitulo, livroDe(ref.livrId), _reacoes);
            _lidos = {..._lidos}..remove(chave);
            if (progresso != null) _lidos[chave] = progresso;
          }
          _feedback = bibliaLeituraUseCase.mensagemVersiculo(
            lido: reacao.vreaLido,
            antes: antes,
            depois: _lidos[chave],
          );
        }
      case Error<VersiculoReacaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    _versiculoGravando = null;
    notifyListeners();
    return result;
  }

  /// Marca o capítulo [ref] como lido, ou desmarca se ele já estava completo.
  Future<Result<CapituloLidoModel?>> _alternarCapitulo(CapituloRef? ref) async {
    final versao = _versao;
    final capitulo = ref == null
        ? null
        : capitulosDo(ref.livrId).where((c) => c.capiNumero == ref.capiNumero).firstOrNull;
    if (versao == null || ref == null || capitulo == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    notifyListeners();

    final result = await bibliaLeituraUseCase.alternarCapitulo(
      versao.versaId,
      capitulo,
      livroDe(ref.livrId),
      lidoDe(ref.livrId, ref.capiNumero),
    );
    switch (result) {
      case Ok<CapituloLidoModel?>(value: final lido):
        final chave = CapituloLidoModel.chaveDe(ref.livrId, ref.capiNumero);
        _lidos = {..._lidos}..remove(chave);
        if (lido != null) _lidos[chave] = lido;
        _feedback = bibliaLeituraUseCase.mensagemCapitulo(lido);
        await _recarregarReacoes();
      case Error<CapituloLidoModel?>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<IndicacoesVersiculo>> _carregarIndicacoes(VersiculoTextoModel versiculo) async {
    _versiculoSelecionado = versiculo;
    _indicacoes = null;
    _limparIndicados();
    notifyListeners();

    final result = await versiculoIndicacaoUseCase.indicacoes(versiculo.versId);
    switch (result) {
      case Ok<IndicacoesVersiculo>(value: final value):
        if (_versiculoSelecionado?.versId == versiculo.versId) {
          await _carregarIndicados(versiculo.versId, value.minha);
          if (_versiculoSelecionado?.versId == versiculo.versId) _indicacoes = value;
        }
      case Error<IndicacoesVersiculo>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<VersiculoIndicacaoModel>> _indicar(String? comentario) async {
    final versiculo = _versiculoSelecionado;
    if (versiculo == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    notifyListeners();

    final atual = _indicacoes?.minha;
    final result = await versiculoIndicacaoUseCase.indicar(versiculo.versId, atual, comentario: comentario);
    switch (result) {
      case Ok<VersiculoIndicacaoModel>(value: final indicacao):
        if (_versiculoSelecionado?.versId == indicacao.versId) {
          final total = _indicacoes?.total ?? 0;
          _indicacoes = (total: atual == null ? total + 1 : total, minha: indicacao);
        }
        if (_versiculos?.any((v) => v.versId == indicacao.versId) ?? false) {
          _indicacoesCapitulo = {..._indicacoesCapitulo, indicacao.versId: indicacao};
        }
      case Error<VersiculoIndicacaoModel>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  Future<Result<void>> _removerIndicacao() async {
    final atual = _indicacoes?.minha;
    if (atual == null) {
      return Result.error(HandledException(message: 'registroNaoEncontrado'));
    }
    notifyListeners();

    final result = await versiculoIndicacaoUseCase.remover(atual);
    switch (result) {
      case Ok<void>():
        final total = _indicacoes?.total ?? 1;
        _indicacoes = (total: total > 0 ? total - 1 : 0, minha: null);
        _indicacoesCapitulo = {..._indicacoesCapitulo}..remove(atual.versId);
        _limparIndicados();
      case Error<void>(error: final error):
        Log.print(error.toString(), name: kApp, title: 'Erro');
    }

    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    carregarCommand.dispose();
    versaoCommand.dispose();
    abrirCapituloCommand.dispose();
    marcarLidoCommand.dispose();
    marcarVersiculoCommand.dispose();
    indicacoesCommand.dispose();
    indicarCommand.dispose();
    removerIndicacaoCommand.dispose();
    adicionarIndicadoCommand.dispose();
    removerIndicadoCommand.dispose();
    consultarPalavraCommand.dispose();
    marcarAoPassarCommand.dispose();
    vozesCommand.dispose();
    if (narrando) unawaited(bibliaLeituraUseCase.pararNarracao());
    unawaited(sairDaLeitura());
    super.dispose();
  }
}
