import 'dart:async';

import 'package:app/config/anotacao_leitura.dart';
import 'package:app/config/command.dart';
import 'package:app/config/dialog_sheet.dart';
import 'package:app/config/ditado_sistema.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/marca_texto.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph, ScrollCacheExtent, ScrollDirection;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:paper_curl/paper_curl.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../use_case/biblia_leitura_usecase.dart';
import '../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'biblia_leitura_viewmodel.dart';
import 'widgets/anotacao_trecho_sheet.dart';
import 'widgets/capitulo_chip.dart';
import 'widgets/compartilhar_trecho_sheet.dart';
import 'widgets/historico_leitura_sheet.dart';
import 'widgets/login_necessario_sheet.dart';
import 'widgets/opcoes_leitura_sheet.dart';
import 'widgets/tags_trecho.dart';
import 'widgets/palavra_dicionario_sheet.dart';
import 'widgets/versiculo_indicacao_sheet.dart';

/// Leitura da Bíblia.
///
/// - Índice: seleção da versão, filtro por testamento (`/v1/testamento`) e livros (`/v1/livro`) com os capítulos da versão
///   (`/v1/biblia/indice/:versaId`); cada livro mostra quantos capítulos foram lidos e cada capítulo indica se
///   está lido, parcialmente lido ou não lido (`/v1/versiculo-reacao/lidos/:versaId`).
/// - Leitura: versículos do capítulo (`/v1/biblia/capitulo/...`), navegação para o capítulo anterior/próximo e
///   botão para marcar ou desmarcar o capítulo como lido (`PUT /v1/versiculo-reacao/capitulo`).
/// - Tocar na linha do versículo só a destaca, como indicativo de onde o usuário está lendo (tocar de novo remove).
/// - Ao lado de cada versículo há duas ações empilhadas, que mudam conforme o estado: em cima, marcar ou desmarcar
///   como lido; embaixo, comentário e indicação, que mostra se o versículo não foi indicado, foi indicado sem
///   comentário ou tem comentário (`/v1/versiculo-indicacao/capitulo/...`). Só esse ícone abre a indicação
///   (`/v1/versiculo-indicacao`), onde o usuário indica, altera o comentário, remove a indicação e escolhe usuários
///   para recebê-la (`/v1/versiculo-indicacao-usuario` e `/v1/usuario/busca`).
/// - Versão (`/v1/versao`): seleção no topo do índice, acima do filtro de testamentos.
/// - AppBar: histórico de leitura e a Configurações de leitura (orientação da tela).
/// - Aberta com destino (`/biblia-leitura?versaId=&livrId=&capiNumero=&versNumero=`, ex.: versículo de um renomado):
///   abre direto no capítulo, na versão do destino, rola até o versículo e o destaca; voltar sai da tela.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeLeitura], [iconeHistorico], [iconeVersao], [iconeAnterior],
/// [iconeProximo], [iconeLido], [iconeNaoLido], [iconeParcial], [iconeComentarIndicar], [iconeIndicadoSemComentario],
/// [iconeComentado], [iconeIndicar],
/// [iconeIndicado], [iconeRemover], [iconeTentarNovamente] e [iconeConfiguracoes] (livro com engrenagem).
class BibliaLeituraView extends StatelessWidget {
  const BibliaLeituraView({super.key, required this.viewModel, this.ditado = const DitadoSistemaAparelho()});

  final BibliaLeituraViewmodel viewModel;

  /// Atalho do microfone na anotação de um trecho.
  final DitadoSistema ditado;

  /// Ícone do menu da leitura e do índice vazio.
  static const iconeLeitura = 'book-open-variant';

  /// Configurações de leitura (AppBar e sheet de opções): livro com engrenagem.
  static const iconeConfiguracoes = 'book-cog-outline';

  /// Botão do histórico de leitura.
  static const iconeHistorico = 'history';

  /// Seleção da versão no índice.
  static const iconeVersao = 'book-multiple';

  static const iconeAnterior = 'chevron-left';
  static const iconeProximo = 'chevron-right';

  /// Capítulo (ou versículo) lido por completo.
  static const iconeLido = 'check-circle';

  /// Capítulo (ou versículo) não lido.
  static const iconeNaoLido = 'check-circle-outline';

  /// Capítulo com parte dos versículos lidos.
  static const iconeParcial = 'progress-check';

  /// Ação, abaixo do ícone de lido, que abre o comentário e a indicação: versículo ainda não indicado.
  static const iconeComentarIndicar = 'comment-text-outline';

  /// Mesma ação, com o versículo indicado sem comentário.
  static const iconeIndicadoSemComentario = 'comment-check-outline';

  /// Mesma ação, com o versículo indicado e comentado.
  static const iconeComentado = 'comment-text';

  /// Versículo ainda não indicado pelo usuário.
  static const iconeIndicar = 'thumb-up-outline';

  /// Versículo já indicado pelo usuário.
  static const iconeIndicado = 'thumb-up';

  static const iconeRemover = 'delete-outline';
  static const iconeTentarNovamente = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  /// O tema escolhido nas Configurações de leitura vale só aqui (e nos sheets abertos daqui); "sistema" usa o do
  /// app. Fica por fora da tela, para todo `Theme.of(context)` dela já pegar o tema escolhido.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, child) {
      final tema = switch (viewModel.tema) {
        TemaApp.sistema => null as ThemeData?,
        TemaApp.claro => AppTheme.light,
        TemaApp.creme => AppTheme.creme,
        TemaApp.escuro => AppTheme.dark,
      };
      // Sempre um Theme (com o do app em "sistema"), para trocar o tema sem recriar a tela.
      return Theme(data: tema ?? Theme.of(context), child: child!);
    },
    child: _BibliaLeitura(viewModel: viewModel, ditado: ditado),
  );
}

class _BibliaLeitura extends StatefulWidget {
  const _BibliaLeitura({required this.viewModel, required this.ditado});

  final BibliaLeituraViewmodel viewModel;
  final DitadoSistema ditado;

  @override
  State<_BibliaLeitura> createState() => _BibliaLeituraViewState();
}

class _BibliaLeituraViewState extends State<_BibliaLeitura> {
  BibliaLeituraViewmodel get _vm => widget.viewModel;

  /// Versículo do destino para onde rolar depois de montar a lista, e a chave da linha dele.
  int? _rolarPara;
  final GlobalKey _alvoKey = GlobalKey();

  /// Páginas da leitura (um capítulo por página), viradas com o efeito de papel do `paper_curl`. Criado ao abrir um
  /// capítulo e descartado ao voltar ao índice.
  PageCurlController? _paginas;

  /// Estado da AppBar na leitura: ao descer o texto ela encolhe e, descendo mais, some (fica só uma alça que a
  /// reabre compacta). Volta ao tamanho normal ao subir, ao chegar no topo ou ao trocar de capítulo.
  _EstadoBarra _barra = _EstadoBarra.normal;

  /// Posição do texto quando a AppBar encolheu: descendo mais [_distanciaOcultar] a partir dela, a barra some.
  double _pixelsCompactou = 0;
  static const double _distanciaOcultar = 80;

  /// Direção da rolagem feita pelo usuário (arrasto e o deslize que o segue).
  ScrollDirection _direcaoUsuario = ScrollDirection.idle;

  /// Navegação flutuante (pílula) visível: some enquanto o texto rola e volta logo depois que ele para.
  bool _navegacaoVisivel = true;
  Timer? _mostrarNavegacao;

  /// Capítulo da última montagem, para restaurar a AppBar e a navegação ao trocar de capítulo.
  CapituloRef? _capituloMontado;

  static const _duracaoBarra = Duration(milliseconds: 200);
  static const _esperaNavegacao = Duration(milliseconds: 900);
  static const double _alturaBarra = 64;
  static const double _alturaBarraCompacta = 44;

  /// Rolagem vertical da leitura: descer compacta a AppBar e subir a expande; enquanto rola, a pílula some.
  bool _aoRolar(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    var barra = _barra;
    final pixels = notification.metrics.pixels;
    if (notification is UserScrollNotification) {
      _direcaoUsuario = notification.direction;
      if (notification.direction == ScrollDirection.reverse && barra == _EstadoBarra.normal) {
        barra = _EstadoBarra.compacta;
        _pixelsCompactou = pixels;
      }
      if (notification.direction == ScrollDirection.forward) barra = _EstadoBarra.normal;
    }
    if (notification is ScrollUpdateNotification) {
      // Continuou descendo depois de encolher: a barra some.
      if (_direcaoUsuario == ScrollDirection.reverse &&
          barra == _EstadoBarra.compacta &&
          pixels - _pixelsCompactou > _distanciaOcultar) {
        barra = _EstadoBarra.oculta;
      }
      // De volta ao topo, a AppBar volta ao normal. Só nas atualizações: a direção é avisada antes do deslocamento,
      // ainda no topo.
      if (pixels <= notification.metrics.minScrollExtent) barra = _EstadoBarra.normal;
    }

    var visivel = _navegacaoVisivel;
    if (notification is ScrollUpdateNotification && (notification.scrollDelta ?? 0) != 0) {
      visivel = false;
      _mostrarNavegacao?.cancel();
    } else if (notification is ScrollEndNotification) {
      _mostrarNavegacao?.cancel();
      _mostrarNavegacao = Timer(_esperaNavegacao, () {
        if (mounted && !_navegacaoVisivel) setState(() => _navegacaoVisivel = true);
      });
    }

    if (barra != _barra || visivel != _navegacaoVisivel) {
      setState(() {
        _barra = barra;
        _navegacaoVisivel = visivel;
      });
    }
    return false;
  }

  /// Linha do versículo sendo narrado, para a tela acompanhar a leitura.
  final GlobalKey _narradoKey = GlobalKey();
  int? _ultimoNarrado;

  /// A cada versículo narrado, rola até ele (só quando muda, para não brigar com a rolagem do usuário).
  void _acompanharNarracao() {
    final narrado = _vm.versiculoNarrado;
    if (narrado == _ultimoNarrado) return;
    _ultimoNarrado = narrado;
    if (narrado == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final narradoContext = _narradoKey.currentContext;
      if (narradoContext != null && narradoContext.mounted) {
        Scrollable.ensureVisible(narradoContext, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
  }

  /// Rola até o versículo do destino quando o capítulo é aberto direto (ex.: a partir de um renomado).
  void _agendarRolagem() {
    final alvo = _vm.consumirVersiculoAlvo();
    if (alvo == null) return;
    _rolarPara = alvo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alvoContext = _alvoKey.currentContext;
      if (alvoContext != null && alvoContext.mounted) {
        Scrollable.ensureVisible(alvoContext, alignment: 0.2, duration: const Duration(milliseconds: 300));
      }
      _rolarPara = null;
    });
  }

  /// Comandos cujo erro vira SnackBar. O erro do carregamento inicial aparece na tela, em [_erroCarregamento].
  List<Listenable> _comandos(BibliaLeituraViewmodel vm) => [
    vm.versaoCommand,
    vm.marcarLidoCommand,
    vm.marcarVersiculoCommand,
    vm.marcarAoPassarCommand,
  ];

  @override
  void initState() {
    super.initState();
    for (final command in _comandos(_vm)) {
      command.addListener(_onResult);
    }
    // Brilho e orientação da leitura valem só aqui: aplicados ao abrir, soltos ao sair (dispose).
    unawaited(_vm.entrarNaLeitura());
  }

  /// A leitura é a tela de cima (sem sheet, menu ou outra página por cima).
  bool _rotaAtual = true;

  /// Sheet aberto pela própria narração (a pergunta de marcar ao passar a página): não para o áudio.
  bool _manterAudio = false;

  /// Abriu um sheet, menu ou outra página por cima da leitura: o áudio para.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final atual = ModalRoute.of(context)?.isCurrent ?? true;
    if (_rotaAtual && !atual && !_manterAudio) {
      // Depois do frame: parar avisa os ouvintes, o que não pode acontecer durante o build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _vm.pararNarracao();
      });
    }
    _rotaAtual = atual;
  }

  @override
  void didUpdateWidget(covariant _BibliaLeitura oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final command in _comandos(oldWidget.viewModel)) {
      command.removeListener(_onResult);
    }
    for (final command in _comandos(_vm)) {
      command.addListener(_onResult);
    }
  }

  @override
  void dispose() {
    for (final command in _comandos(_vm)) {
      command.removeListener(_onResult);
    }
    _paginas?.dispose();
    _mostrarNavegacao?.cancel();
    _vm.pararNarracaoAoSair();
    unawaited(_vm.sairDaLeitura());
    super.dispose();
  }

  void _onResult() {
    for (final Command command in [
      _vm.versaoCommand,
      _vm.marcarLidoCommand,
      _vm.marcarVersiculoCommand,
      _vm.marcarAoPassarCommand,
    ]) {
      if (command.error) {
        final mensagem = BibliaLeituraView.mensagemErro(command.result);
        command.clearResult();
        _mostrarMensagem(mensagem);
      }
    }
    // Confirmação da marcação de lido (capítulo ou versículo).
    if (_vm.consumirFeedback() case (:final mensagem, :final lido)) {
      HapticFeedback.lightImpact();
      _mostrarMensagem(mensagem, lido: lido);
    }
  }

  /// SnackBar com a [mensagem] (chave de tradução); substitui a anterior para não acumular em toques seguidos.
  /// [lido] mostra o ícone de lido (true) ou não lido (false) da confirmação; nulo é erro, sem ícone.
  void _mostrarMensagem(String mensagem, {bool? lido}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final scheme = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: lido == null ? 4 : 2),
          content: Row(
            children: [
              if (lido != null) ...[
                BibliaLeituraView.icone(
                  lido ? BibliaLeituraView.iconeLido : BibliaLeituraView.iconeNaoLido,
                  lido ? Icons.check_circle : Icons.check_circle_outline,
                  size: 20,
                  color: scheme.inversePrimary,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(AppLocalizations.of(context).translate(mensagem))),
            ],
          ),
        ),
      );
  }

  void _abrirHistorico() {
    HistoricoLeituraSheet.show(context, viewModel: _vm);
  }

  void _abrirVersiculo(VersiculoTextoModel versiculo) {
    _vm.indicacoesCommand.execute(versiculo);
    VersiculoIndicacaoSheet.show(context, viewModel: _vm, titulo: versiculo.referencia);
  }

  String _tituloCapitulo(CapituloRef ref) {
    final nome = _vm.livroDe(ref.livrId)?.livrNome ?? '';
    return '$nome ${ref.capiNumero}'.trim();
  }

  /// A leitura é a primeira tela (ex.: `ROTA_INICIAL` do `.env`): sair dela vai para a `/home` em vez de fechar o
  /// app. Só com o GoRouter (nos testes de widget a tela abre direto no `MaterialApp`).
  bool get _semTelaAnterior => GoRouter.maybeOf(context) != null && !Navigator.of(context).canPop();

  /// Sair da leitura (índice, ou capítulo aberto por destino) quando ela é a primeira tela.
  void _irParaHome() {
    _vm.pararNarracao();
    unawaited(_vm.sairDaLeitura());
    context.go(Routes.home);
  }

  /// Configurações de leitura; ao voltar, reaplica a orientação (que lá pode ter mudado).
  Future<void> _abrirConfiguracao() async {
    await context.push(Routes.configuracoesLeitura, extra: _vm);
    if (mounted) unawaited(_vm.entrarNaLeitura());
  }

  /// Sheet de baixo para escolher entre as Configurações de leitura e as do app.
  Future<void> _escolherConfiguracao() async {
    final strings = AppLocalizations.of(context);
    final abrir = await DialogSheet.show<VoidCallback>(
      context,
      titulo: strings.translate('configuracoes'),
      conteudo: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: BibliaLeituraView.icone(BibliaLeituraView.iconeConfiguracoes, Icons.settings_outlined),
              title: Text(strings.translate('configuracoesLeitura')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(sheetContext).pop<VoidCallback>(_abrirConfiguracao),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: Text(strings.translate('configuracoesApp')),
              subtitle: _vm.logado ? null : Text(strings.translate('entreParaAcessar')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(sheetContext).pop<VoidCallback>(_abrirConfiguracaoApp),
            ),
          ],
        ),
      ),
    );
    if (abrir != null && mounted) abrir();
  }

  /// Configurações do app (`/configuracao`, a página que já existia). Ela exige login: sem login, um sheet
  /// explica que é restrita a quem está logado e oferece "Voltar" ou "Continuar para o login".
  Future<void> _abrirConfiguracaoApp() async {
    if (_vm.logado) {
      await _foraDaLeitura(Routes.configuracao);
      return;
    }
    final strings = AppLocalizations.of(context);
    final entrar = await LoginNecessarioSheet.perguntar(
      context,
      titulo: strings.translate('configuracoesApp'),
      mensagem: 'funcionalidadeRestritaLogin',
    );
    if (entrar && mounted) await _foraDaLeitura(Routes.login);
  }

  /// Abre uma tela que não é da leitura: brilho e orientação voltam aos do sistema enquanto ela está aberta e
  /// são reaplicados ao voltar.
  Future<void> _foraDaLeitura(String rota) async {
    await _vm.sairDaLeitura();
    if (!mounted) return;
    await context.push(rota);
    if (mounted) await _vm.entrarNaLeitura();
  }

  /// AppBar que encolhe (altura, título e ícones) quando compacta e, oculta, vira só uma alça que a reabre compacta.
  Widget _appBarAnimada(AppLocalizations strings) {
    return AnimatedSize(
      duration: _duracaoBarra,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: _barra == _EstadoBarra.oculta ? _alcaBarra(strings) : _appBarRedimensionada(strings),
    );
  }

  /// Faixa fina no lugar da AppBar oculta, com uma alça; tocar reabre a barra compacta.
  Widget _alcaBarra(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor ?? scheme.surface,
      child: Tooltip(
        message: strings.translate('mostrarBarra'),
        child: InkWell(
          onTap: () => setState(() => _barra = _EstadoBarra.compacta),
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: SizedBox(
              height: 20,
              width: double.infinity,
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: scheme.outline, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBarRedimensionada(AppLocalizations strings) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _barra == _EstadoBarra.normal ? 0 : 1),
      duration: _duracaoBarra,
      curve: Curves.easeOut,
      builder: (context, t, _) => Theme(
        data: theme.copyWith(
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(iconSize: 24 - 4 * t, visualDensity: t > 0.5 ? VisualDensity.compact : null),
          ),
        ),
        child: _appBar(
          strings,
          altura: _alturaBarra - (_alturaBarra - _alturaBarraCompacta) * t,
          estiloTitulo: TextStyle.lerp(theme.textTheme.titleLarge, theme.textTheme.titleSmall, t),
        ),
      ),
    );
  }

  AppBar _appBar(AppLocalizations strings, {double? altura, TextStyle? estiloTitulo}) {
    final ref = _vm.capitulo;
    final fechaCapitulo = ref != null && !_vm.abertaPorDestino;
    return AppBar(
      toolbarHeight: altura,
      titleTextStyle: estiloTitulo,
      leading: fechaCapitulo
          ? IconButton(
              tooltip: strings.translate('voltar'),
              onPressed: _vm.fecharCapitulo,
              icon: const Icon(Icons.arrow_back),
            )
          : _semTelaAnterior
          ? IconButton(tooltip: strings.translate('home'), onPressed: _irParaHome, icon: const Icon(Icons.arrow_back))
          : null,
      title: Text(ref == null ? strings.translate('leituraBiblica') : _tituloCapitulo(ref)),
      actions: [
        // Histórico, progresso e marcações são do usuário: só aparecem com login.
        if (_vm.logado)
          IconButton(
            tooltip: strings.translate('historicoLeitura'),
            onPressed: _vm.indice == null ? null : _abrirHistorico,
            icon: BibliaLeituraView.icone(BibliaLeituraView.iconeHistorico, Icons.history),
          ),
        // Livro com engrenagem: sheet com as Configurações de leitura e as do app.
        IconButton(
          tooltip: strings.translate('configuracoes'),
          onPressed: _escolherConfiguracao,
          icon: BibliaLeituraView.icone(BibliaLeituraView.iconeConfiguracoes, Icons.settings_outlined),
        ),
      ],
    );
  }

  /// Seleção da versão (`/v1/versao`), no topo do índice, logo acima do filtro de testamentos.
  /// Sem login, trocar a versão é restrito: o campo mostra a versão atual e tocar pede o login.
  Future<void> _versaoSemLogin() async {
    final strings = AppLocalizations.of(context);
    final entrar = await LoginNecessarioSheet.perguntar(
      context,
      titulo: strings.translate('versaoBiblia'),
      mensagem: 'selecaoVersaoRestritaLogin',
    );
    if (entrar && mounted) await _foraDaLeitura(Routes.login);
  }

  Widget _versaoSelecao(AppLocalizations strings) {
    if (!_vm.logado) {
      final versao = _vm.versao;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: InkWell(
          key: const ValueKey('versaoSemLogin'),
          borderRadius: BorderRadius.circular(4),
          onTap: _versaoSemLogin,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: strings.translate('versao'),
              prefixIcon: BibliaLeituraView.icone(BibliaLeituraView.iconeVersao, Icons.library_books_outlined),
              suffixIcon: const Icon(Icons.lock_outline),
            ),
            child: Text(
              versao == null ? '—' : '${versao.versaCodigo} · ${versao.versaNome}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<int>(
        key: ValueKey(_vm.versao?.versaId),
        initialValue: _vm.versao?.versaId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('versao'),
          prefixIcon: BibliaLeituraView.icone(BibliaLeituraView.iconeVersao, Icons.library_books_outlined),
        ),
        items: [
          for (final versao in _vm.versoes)
            DropdownMenuItem(
              value: versao.versaId,
              child: Text('${versao.versaCodigo} · ${versao.versaNome}', overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _vm.versaoCommand.running
            ? null
            : (versaId) {
                final versao = _vm.versoes.where((v) => v.versaId == versaId).firstOrNull;
                if (versao != null) _vm.versaoCommand.execute(versao);
              },
      ),
    );
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.carregarCommand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(BibliaLeituraView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: BibliaLeituraView.icone(BibliaLeituraView.iconeTentarNovamente, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtroTestamento(AppLocalizations strings) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(strings.translate('todos')),
            selected: _vm.testamentoId == null,
            onSelected: (_) => _vm.selecionarTestamento(null),
          ),
          for (final testamento in _vm.testamentos) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(testamento.testNome),
              selected: _vm.testamentoId == testamento.testId,
              onSelected: (_) => _vm.selecionarTestamento(testamento.testId),
            ),
          ],
        ],
      ),
    );
  }

  Widget _indice(AppLocalizations strings) {
    final livros = _vm.livros;
    return Column(
      children: [
        if (_vm.versaoCommand.running) const LinearProgressIndicator(),
        if (_vm.versoes.isNotEmpty) _versaoSelecao(strings),
        _filtroTestamento(strings),
        Expanded(
          child: livros.isEmpty
              ? Center(child: Text(strings.translate('nenhumLivroDisponivel')))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: livros.length,
                  itemBuilder: (_, index) => _livro(livros[index], strings),
                ),
        ),
      ],
    );
  }

  Widget _livro(LivroModel livro, AppLocalizations strings) {
    final capitulos = _vm.capitulosDo(livro.livrId);
    final progresso = _vm.progressoDo(livro.livrId);
    final scheme = Theme.of(context).colorScheme;
    final completo = progresso.completos == progresso.total && progresso.total > 0;

    return ExpansionTile(
      key: PageStorageKey('livro-${livro.livrId}'),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completo ? scheme.secondaryContainer : Colors.transparent,
          border: completo ? null : Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          livro.livrAbrev,
          style: TextStyle(fontSize: 12, color: completo ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
        ),
      ),
      title: Text(livro.livrNome),
      subtitle: !_vm.logado
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${progresso.completos}/${progresso.total} ${strings.translate('capitulosLidos')}'
                  '${progresso.emAndamento > 0 ? ' · ${progresso.emAndamento} ${strings.translate('emAndamento')}' : ''}',
                ),
                const SizedBox(height: 4),
                // Avança por versículo lido, para a leitura parcial também aparecer na barra.
                LinearProgressIndicator(value: progresso.fracao, minHeight: 6, borderRadius: BorderRadius.circular(3)),
              ],
            ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedAlignment: Alignment.centerLeft,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final capitulo in capitulos)
              CapituloChip(
                numero: capitulo.capiNumero,
                lido: _vm.lidoDe(livro.livrId, capitulo.capiNumero),
                onTap: () => _vm.abrirCapituloCommand.execute((livrId: livro.livrId, capiNumero: capitulo.capiNumero)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _leitura(AppLocalizations strings) {
    final versiculos = _vm.versiculos;
    final command = _vm.abrirCapituloCommand;

    if (versiculos == null) {
      if (command.running || _vm.versaoCommand.running) return const Center(child: CircularProgressIndicator());
      final ref = _vm.capitulo!;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(BibliaLeituraView.mensagemErro(command.result))),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => command.execute(ref),
              icon: BibliaLeituraView.icone(BibliaLeituraView.iconeTentarNovamente, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final lido = _vm.lidoAtual;
    _agendarRolagem();
    _acompanharNarracao();
    // Narração contínua terminou o capítulo: vira a página (com a animação) e ela segue no próximo.
    if (_vm.consumirPassagemAutomatica() case final destino?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _virarPagina(destino, frente: true);
      });
    }

    return ListView.builder(
      // Enquanto há rolagem pendente, monta o capítulo inteiro para a linha do versículo existir.
      scrollCacheExtent: _rolarPara != null ? const ScrollCacheExtent.pixels(100000) : null,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, _espacoNavegacao),
      itemCount: versiculos.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(_vm.versao?.versaNome ?? '', style: textTheme.labelLarge)),
                if (lido != null)
                  Chip(
                    avatar: BibliaLeituraView.icone(
                      lido.completo ? BibliaLeituraView.iconeLido : BibliaLeituraView.iconeParcial,
                      lido.completo ? Icons.check_circle : Icons.timelapse,
                      size: 18,
                    ),
                    label: Text(
                      lido.completo
                          ? strings.translate('capituloLido')
                          : '${lido.versLidos}/${lido.versTotal} ${strings.translate('versiculosLidos')}',
                    ),
                  ),
              ],
            ),
          );
        }
        final versiculo = versiculos[index - 1];
        return Row(
          key: versiculo.versId == _rolarPara
              ? _alvoKey
              : versiculo.versId == _vm.versiculoNarrado
              ? _narradoKey
              : null,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _vm.destacarVersiculo(versiculo.versId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _vm.versiculoNarrado == versiculo.versId
                        ? scheme.primaryContainer
                        : _vm.versiculoDestacado == versiculo.versId
                        ? _corDestaque()
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    // Toque longo seleciona a palavra (e abre o dicionário); arrastar sem soltar seleciona mais.
                    child: GestureDetector(
                      // Tocar num trecho marcado mostra o trecho; fora de marcação, destaca o versículo.
                      onTapUp: (detalhes) => _tocarTexto(versiculo, detalhes.globalPosition),
                      onLongPressStart: (detalhes) => _iniciarSelecao(detalhes.globalPosition),
                      onLongPressMoveUpdate: (detalhes) => _estenderSelecao(detalhes.globalPosition),
                      onLongPressEnd: (_) => _concluirSelecao(),
                      child: Text.rich(
                        key: _textoKeys.putIfAbsent(versiculo.versId, GlobalKey.new),
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${versiculo.versNumero}  ',
                              style: textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ..._textoMarcado(
                              versiculo,
                              _estiloVersiculo(textTheme),
                              _vm.marcasDe(_vm.capitulo!),
                              indice: index - 1,
                              anotados: _vm.trechosAnotados(_vm.capitulo!, index - 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_vm.logado)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [_marcaVersiculo(versiculo, strings), _comentarIndicarVersiculo(versiculo, strings)],
              ),
          ],
        );
      },
    );
  }

  /// Ícone que marca ou desmarca o versículo como lido; mostra progresso enquanto grava.
  Widget _marcaVersiculo(VersiculoTextoModel versiculo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final lido = _vm.versiculoLido(versiculo.versId);
    final gravando = _vm.versiculoGravando == versiculo.versId;

    return IconButton(
      tooltip: strings.translate(lido ? 'desmarcarVersiculoLido' : 'marcarVersiculoLido'),
      visualDensity: VisualDensity.compact,
      onPressed: _vm.marcarVersiculoCommand.running ? null : () => _vm.marcarVersiculoCommand.execute(versiculo),
      icon: gravando
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : BibliaLeituraView.icone(
              lido ? BibliaLeituraView.iconeLido : BibliaLeituraView.iconeNaoLido,
              lido ? Icons.check_circle : Icons.check_circle_outline,
              size: 20,
              color: lido ? scheme.primary : scheme.outline,
            ),
    );
  }

  /// Cor do destaque da linha tocada: o amarelo de destaque da leitura, se o tema tiver [ReadingColors].
  Color _corDestaque() =>
      Theme.of(context).extension<ReadingColors>()?.highlightYellow ?? Theme.of(context).colorScheme.secondaryContainer;

  /// Ícone, abaixo do de lido, que abre o comentário e a indicação do versículo. Como o de lido, muda com o estado:
  /// contorno (não indicado), indicado sem comentário e preenchido (com comentário), na cor primária quando indicado.
  Widget _comentarIndicarVersiculo(VersiculoTextoModel versiculo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final estado = _vm.estadoIndicacao(versiculo.versId);
    final (chave, fallback, tooltip) = switch (estado) {
      EstadoIndicacao.nenhuma => (
        BibliaLeituraView.iconeComentarIndicar,
        Icons.comment_outlined,
        'comentarIndicarVersiculo',
      ),
      EstadoIndicacao.indicado => (
        BibliaLeituraView.iconeIndicadoSemComentario,
        Icons.mark_chat_read_outlined,
        'versiculoIndicadoSemComentario',
      ),
      EstadoIndicacao.comentado => (BibliaLeituraView.iconeComentado, Icons.comment, 'versiculoComComentario'),
    };
    final indicado = estado != EstadoIndicacao.nenhuma;

    return IconButton(
      tooltip: strings.translate(tooltip),
      visualDensity: VisualDensity.compact,
      onPressed: () => _abrirVersiculo(versiculo),
      icon: BibliaLeituraView.icone(chave, fallback, size: 20, color: indicado ? scheme.primary : scheme.outline),
    );
  }

  /// Espaço no fim das listas da leitura para o último versículo não ficar sob a navegação flutuante.
  static const double _espacoNavegacao = 96;

  /// Texto do versículo no tamanho escolhido nas opções de leitura.
  TextStyle? _estiloVersiculo(TextTheme textTheme) {
    final base = textTheme.bodyLarge;
    return base?.copyWith(height: 1.5, fontSize: (base.fontSize ?? 16) * _vm.escalaFonte);
  }

  /// Navegação flutuante da leitura: capítulo anterior, opções de leitura (centro) e próximo capítulo.
  Widget _navegacaoLeitura(AppLocalizations strings) {
    final anterior = _vm.anterior;
    final proximo = _vm.proximo;
    final scheme = Theme.of(context).colorScheme;
    // Sem as setas (opções de leitura), a pílula fica só com o botão de opções; virar arrastando a borda continua.
    final setas = _vm.mostrarSetas;

    final paginas = _paginas;
    final virando = paginas?.isTurning ?? false;
    final pilula = Material(
      elevation: 3,
      color: scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (setas) ...[
              IconButton(
                tooltip: strings.translate('capituloAnterior'),
                onPressed: anterior == null ? null : () => _virarPagina(anterior, frente: false),
                icon: BibliaLeituraView.icone(BibliaLeituraView.iconeAnterior, Icons.chevron_left),
              ),
              const SizedBox(width: 8),
            ],
            // Some assim que a página começa a virar e volta quando ela assenta (ou a virada é desfeita).
            AnimatedOpacity(
              opacity: virando ? 0 : 1,
              duration: const Duration(milliseconds: 120),
              child: IgnorePointer(
                ignoring: virando,
                child: IconButton.filled(
                  tooltip: strings.translate('opcoesLeitura'),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                  ),
                  onPressed: _abrirOpcoes,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
            ),
            // Narração: lê o capítulo a partir do versículo destacado (ou do começo); tocar de novo para.
            if (_vm.narracaoDisponivel) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: strings.translate(_vm.narrando ? 'pararNarracao' : 'ouvirCapitulo'),
                isSelected: _vm.narrando,
                onPressed: _vm.versiculos == null ? null : _vm.alternarNarracao,
                icon: const Icon(Icons.volume_up_outlined),
                selectedIcon: const Icon(Icons.stop_circle_outlined),
              ),
            ],
            if (setas) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: strings.translate('proximoCapitulo'),
                onPressed: proximo == null ? null : () => _virarPagina(proximo, frente: true),
                icon: BibliaLeituraView.icone(BibliaLeituraView.iconeProximo, Icons.chevron_right),
              ),
            ],
          ],
        ),
      ),
    );
    // Sem as setas, a pílula só tem o botão de opções: some inteira durante a virada.
    if (setas) return pilula;
    return AnimatedOpacity(
      opacity: virando ? 0 : 1,
      duration: const Duration(milliseconds: 120),
      child: IgnorePointer(ignoring: virando, child: pilula),
    );
  }

  /// Texto de cada versículo do capítulo aberto, por `versId`, para achar a palavra sob o dedo.
  final Map<int, GlobalKey> _textoKeys = {};

  /// Seleção feita com o toque longo: [_selecaoAncora] é a palavra onde o dedo começou e [_selecaoFoco] a palavra
  /// onde ele está (versículo pelo índice na lista e intervalo da palavra no texto dele). Fica destacada até o
  /// sheet (dicionário ou trecho) fechar.
  ({int indice, int inicio, int fim})? _selecaoAncora;
  ({int indice, int inicio, int fim})? _selecaoFoco;

  /// Começo e fim (exclusivo) da seleção, na ordem do texto.
  (({int indice, int offset}), ({int indice, int offset}))? get _selecao {
    final ancora = _selecaoAncora;
    final foco = _selecaoFoco;
    if (ancora == null || foco == null) return null;
    final focoAntes = foco.indice < ancora.indice || (foco.indice == ancora.indice && foco.inicio < ancora.inicio);
    final primeira = focoAntes ? foco : ancora;
    final ultima = focoAntes ? ancora : foco;
    return ((indice: primeira.indice, offset: primeira.inicio), (indice: ultima.indice, offset: ultima.fim));
  }

  /// Texto do versículo com as marcações do marca-texto ([marcas]), as partes com anotação ([anotados], pintadas
  /// na cor da anotação) e, na página atual ([indice] é a posição dele na lista), a seleção em andamento por
  /// cima.
  List<TextSpan> _textoMarcado(
    VersiculoTextoModel versiculo,
    TextStyle? estilo,
    List<MarcaTexto> marcas, {
    int? indice,
    List<({int inicio, int fim, CorTag? cor})> anotados = const [],
  }) {
    final texto = versiculo.versTexto;
    final doVersiculo = [
      for (final m in marcas)
        if (m.versId == versiculo.versId && m.inicio < texto.length) m,
    ];

    ({int inicio, int fim})? selecionado;
    final selecao = _selecao;
    if (indice != null && selecao != null) {
      final (inicio, fim) = selecao;
      if (indice >= inicio.indice && indice <= fim.indice) {
        final de = indice == inicio.indice ? inicio.offset.clamp(0, texto.length) : 0;
        final ate = indice == fim.indice ? fim.offset.clamp(de, texto.length) : texto.length;
        if (ate > de) selecionado = (inicio: de, fim: ate);
      }
    }
    if (doVersiculo.isEmpty && selecionado == null && anotados.isEmpty) return [TextSpan(text: texto, style: estilo)];

    final cores = Theme.of(context).extension<ReadingColors>();
    final corSelecao = Theme.of(context).colorScheme.primary.withValues(alpha: 0.28);
    final limites = <int>{0, texto.length};
    for (final m in doVersiculo) {
      limites
        ..add(m.inicio)
        ..add(m.fim.clamp(0, texto.length));
    }
    if (selecionado != null) {
      limites
        ..add(selecionado.inicio)
        ..add(selecionado.fim);
    }
    for (final a in anotados) {
      limites
        ..add(a.inicio)
        ..add(a.fim);
    }
    final corAnotacao = Theme.of(context).colorScheme.primary;
    final pontos = limites.toList()..sort();

    return [
      for (var k = 0; k + 1 < pontos.length; k++)
        if (pontos[k + 1] > pontos[k])
          () {
            final (de, ate) = (pontos[k], pontos[k + 1]);
            final naSelecao = selecionado != null && de >= selecionado.inicio && ate <= selecionado.fim;
            final marca = doVersiculo.lastWhere((m) => de >= m.inicio && ate <= m.fim, orElse: () => _semMarca);
            final marcado = !identical(marca, _semMarca);
            final anotacao = anotados.where((a) => de >= a.inicio && ate <= a.fim).lastOrNull;
            final corTag = anotacao?.cor?.cor;
            // Com tag, o trecho fica na cor da tag (por cima do marca-texto). Sem tag: o marca-texto, se houver,
            // com a anotação num sublinhado; senão, a anotação pintada na cor do tema.
            final fundo = naSelecao
                ? corSelecao
                : corTag != null
                ? corTag.withValues(alpha: 0.28)
                : marcado
                ? cores?.highlight(marca.cor) ?? Theme.of(context).colorScheme.secondaryContainer
                : anotacao != null
                ? corAnotacao.withValues(alpha: 0.28)
                : null;
            final sublinhar = anotacao != null && corTag == null && marcado && !naSelecao;
            return TextSpan(
              text: texto.substring(de, ate),
              style: fundo == null
                  ? estilo
                  : (estilo ?? const TextStyle()).copyWith(
                      backgroundColor: fundo,
                      decoration: sublinhar ? TextDecoration.underline : null,
                      decorationStyle: sublinhar ? TextDecorationStyle.dotted : null,
                      decorationColor: sublinhar ? corAnotacao : null,
                      decorationThickness: sublinhar ? 2 : null,
                    ),
            );
          }(),
    ];
  }

  static const MarcaTexto _semMarca = (versId: -1, inicio: 0, fim: 0, cor: HighlightColor.amarelo);

  /// Marca-texto do trecho: "Desmarcar texto" se ele estiver marcado, senão "Marcar texto" na cor das
  /// Configurações de leitura. No sheet do trecho alterna sem fechar; no do dicionário ([fechar]) fecha o sheet.
  Widget _seletorMarcaTexto(
    BuildContext sheetContext,
    ({int indice, int offset}) inicio,
    ({int indice, int offset}) fim, {
    bool fechar = false,
  }) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final marcado = _vm.trechoMarcado(inicio, fim);
    final cor = Theme.of(context).extension<ReadingColors>()?.highlight(_vm.corMarcaTexto);
    return OutlinedButton.icon(
      key: const ValueKey('alternarMarcaTexto'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(DialogSheet.alturaAcao)),
      onPressed: () {
        if (marcado) {
          _vm.desmarcarTrecho(inicio, fim);
        } else {
          _vm.marcarTrecho(inicio, fim, _vm.corMarcaTexto);
        }
        if (fechar) Navigator.of(sheetContext).pop();
      },
      icon: marcado
          ? const Icon(Icons.format_color_reset_outlined)
          : Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
      label: Text(strings.translate(marcado ? 'desmarcarTexto' : 'marcarTexto')),
    );
  }

  /// Posição (versículo e caractere no texto dele) sob [posicaoGlobal]; nula fora do texto de um versículo.
  ({int indice, int offset})? _posicaoEm(Offset posicaoGlobal) {
    final versiculos = _vm.versiculos;
    if (versiculos == null) return null;
    for (final (indice, versiculo) in versiculos.indexed) {
      final textoContext = _textoKeys[versiculo.versId]?.currentContext;
      if (textoContext == null || !textoContext.mounted) continue;
      final paragrafo = _paragrafo(textoContext.findRenderObject());
      if (paragrafo == null || !paragrafo.attached) continue;
      final local = paragrafo.globalToLocal(posicaoGlobal);
      if (local.dy < 0 || local.dy > paragrafo.size.height) continue;
      final prefixo = paragrafo.text.toPlainText().length - versiculo.versTexto.length;
      final offset = paragrafo.getPositionForOffset(local).offset - prefixo;
      if (offset < 0) return null;
      return (indice: indice, offset: offset);
    }
    return null;
  }

  /// Toque no texto: dentro de um trecho anotado ou marcado, abre o trecho (destacado enquanto o sheet estiver
  /// aberto), com a anotação se houver; senão, destaca o versículo.
  Future<void> _tocarTexto(VersiculoTextoModel versiculo, Offset posicaoGlobal) async {
    final posicao = _posicaoEm(posicaoGlobal);
    final trecho = posicao == null
        ? null
        : _vm.trechoDaAnotacaoEm(posicao.indice, posicao.offset) ?? _vm.trechoDaMarcaEm(posicao.indice, posicao.offset);
    if (trecho == null) {
      _vm.destacarVersiculo(versiculo.versId);
      return;
    }
    final (inicio, fim) = trecho;
    setState(() {
      _selecaoAncora = (indice: inicio.indice, inicio: inicio.offset, fim: inicio.offset);
      _selecaoFoco = (indice: fim.indice, inicio: fim.offset, fim: fim.offset);
    });
    await _mostrarTrecho(inicio, fim);
    _limparSelecao();
  }

  void _limparSelecao() {
    if (!mounted) return;
    setState(() {
      _selecaoAncora = null;
      _selecaoFoco = null;
    });
  }

  /// Sheet do trecho de [inicio] a [fim] do capítulo aberto, com a referência.
  Future<void> _mostrarTrecho(({int indice, int offset}) inicio, ({int indice, int offset}) fim) async {
    final versiculos = _vm.versiculos;
    final ref = _vm.capitulo;
    if (versiculos == null || ref == null) return;
    final referencia = BibliaLeituraUseCase.referenciaTrecho(
      _tituloCapitulo(ref),
      versiculos[inicio.indice].versNumero,
      versiculos[fim.indice].versNumero,
    );
    final texto = BibliaLeituraUseCase.trecho(versiculos, inicio, fim);
    final acao = await _abrirTrecho(texto, referencia, inicio, fim);
    if (!mounted) return;
    switch (acao) {
      case _AcaoTrecho.compartilhar:
        await _abrirCompartilhar(texto, referencia);
      case _AcaoTrecho.anotar:
        await _abrirAnotacao(referencia, inicio, fim);
      case null:
        break;
    }
  }

  /// Sheet da mensagem opcional e, ao confirmar, o compartilhamento do sistema.
  Future<void> _abrirCompartilhar(String texto, String referencia) => DialogSheet.show<void>(
    context,
    titulo: AppLocalizations.of(context).translate('compartilhar'),
    conteudo: CompartilharTrechoSheet(
      texto: texto,
      referencia: referencia,
      onCompartilhar: (mensagem) => _vm.compartilharTrecho(texto, referencia, mensagem: mensagem),
    ),
  );

  /// Sheet da anotação do trecho (nova ou a existente, para editar ou excluir o texto; as tags do trecho ficam).
  Future<void> _abrirAnotacao(String referencia, ({int indice, int offset}) inicio, ({int indice, int offset}) fim) {
    final atual = _vm.anotacaoDoTrecho(inicio, fim);
    final anotacao = atual != null && atual.texto.isNotEmpty ? atual : null;
    return DialogSheet.show<void>(
      context,
      titulo: referencia,
      isDismissible: false,
      conteudo: AnotacaoTrechoSheet(
        ditado: widget.ditado,
        anotacao: anotacao,
        onSalvar: (texto) {
          _vm.salvarAnotacao(inicio, fim, texto: texto);
          _mostrarMensagem('anotacaoSalva');
        },
        onExcluir: anotacao == null
            ? null
            : () {
                _vm.excluirAnotacao(inicio, fim);
                _mostrarMensagem('anotacaoExcluida');
              },
      ),
    );
  }

  /// Palavra sob [posicaoGlobal] no texto de um versículo visível; nula fora do texto ou sem letra ali.
  ({int indice, int inicio, int fim})? _palavraEm(Offset posicaoGlobal) {
    final posicao = _posicaoEm(posicaoGlobal);
    final versiculos = _vm.versiculos;
    if (posicao == null || versiculos == null) return null;
    final intervalo = _vm.intervaloPalavraEm(versiculos[posicao.indice].versTexto, posicao.offset);
    if (intervalo == null) return null;
    return (indice: posicao.indice, inicio: intervalo.inicio, fim: intervalo.fim);
  }

  void _iniciarSelecao(Offset posicaoGlobal) {
    final palavra = _palavraEm(posicaoGlobal);
    if (palavra == null) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _selecaoAncora = palavra;
      _selecaoFoco = palavra;
    });
  }

  /// Arrastando sem soltar: a seleção vai até a palavra sob o dedo (fora do texto, fica onde estava).
  void _estenderSelecao(Offset posicaoGlobal) {
    if (_selecaoAncora == null) return;
    final palavra = _palavraEm(posicaoGlobal);
    if (palavra == null || palavra == _selecaoFoco) return;
    setState(() => _selecaoFoco = palavra);
  }

  /// Soltou: uma palavra abre o dicionário; mais de uma abre o trecho (copiar e ouvir). A seleção some ao fechar.
  Future<void> _concluirSelecao() async {
    final selecao = _selecao;
    final versiculos = _vm.versiculos;
    if (selecao == null || versiculos == null) return;
    final (inicio, fim) = selecao;

    if (_selecaoAncora == _selecaoFoco) {
      await _abrirPalavra(BibliaLeituraUseCase.trecho(versiculos, inicio, fim), selecao: selecao);
    } else {
      // Selecionou um trecho: já fica marcado na cor das Configurações de leitura ("Desmarcar texto" desfaz).
      if (_vm.marcaTextoDisponivel && !_vm.trechoMarcado(inicio, fim)) {
        _vm.marcarTrecho(inicio, fim, _vm.corMarcaTexto);
      }
      await _mostrarTrecho(inicio, fim);
    }
    _limparSelecao();
  }

  /// Sheet do trecho selecionado, de cima para baixo: o texto (em destaque, na cor da marcação) e a anotação, se
  /// houver; as tags; "Desmarcar texto"/"Marcar texto"; e as ações Copiar (texto e referência), Compartilhar,
  /// Anotar e Ouvir numa linha. Compartilhar e Anotar fecham o sheet e devolvem a ação, para o sheet seguinte abrir
  /// com o trecho ainda selecionado.
  Future<_AcaoTrecho?> _abrirTrecho(
    String texto,
    String referencia,
    ({int indice, int offset}) inicio,
    ({int indice, int offset}) fim,
  ) async {
    final strings = AppLocalizations.of(context);
    return DialogSheet.show<_AcaoTrecho>(
      context,
      titulo: referencia,
      conteudo: Builder(
        builder: (sheetContext) => ListenableBuilder(
          listenable: _vm,
          builder: (sheetContext, _) {
            // Só conta como anotação o trecho com texto (um trecho pode ter só tags).
            final registro = _vm.anotacaoDisponivel ? _vm.anotacaoDoTrecho(inicio, fim) : null;
            final anotacao = registro != null && registro.texto.isNotEmpty ? registro : null;
            final acoes = <Widget>[
              _acaoTrecho(Icons.copy, strings.translate('copiar'), () async {
                await Clipboard.setData(ClipboardData(text: '"$texto" ($referencia)'));
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                _mostrarMensagem('trechoCopiado');
              }),
              if (_vm.compartilhamentoDisponivel)
                _acaoTrecho(
                  Icons.share_outlined,
                  strings.translate('compartilhar'),
                  () => Navigator.of(sheetContext).pop(_AcaoTrecho.compartilhar),
                ),
              if (_vm.anotacaoDisponivel)
                _acaoTrecho(
                  anotacao == null ? Icons.edit_note : Icons.edit_outlined,
                  strings.translate(anotacao == null ? 'anotar' : 'editarAnotacao'),
                  () => Navigator.of(sheetContext).pop(_AcaoTrecho.anotar),
                ),
              if (_vm.narracaoDisponivel)
                _acaoTrecho(Icons.volume_up_outlined, strings.translate('ouvir'), () {
                  Navigator.of(sheetContext).pop();
                  _vm.ouvirTrecho(texto);
                }),
            ];
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _textoDoTrecho(texto, inicio, fim),
                  if (anotacao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _anotacaoCard(anotacao, () => Navigator.of(sheetContext).pop(_AcaoTrecho.anotar)),
                    ),
                  const SizedBox(height: 16),
                  if (_vm.anotacaoDisponivel) TagsTrecho(viewModel: _vm, inicio: inicio, fim: fim),
                  if (_vm.marcaTextoDisponivel) _seletorMarcaTexto(sheetContext, inicio, fim),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, acao) in acoes.indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: acao),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// O texto selecionado em destaque: fundo na cor da marcação (se marcado) e uma barra à esquerda.
  Widget _textoDoTrecho(String texto, ({int indice, int offset}) inicio, ({int indice, int offset}) fim) {
    final scheme = Theme.of(context).colorScheme;
    final marca = _vm.marcaTextoDisponivel && _vm.trechoMarcado(inicio, fim)
        ? Theme.of(context).extension<ReadingColors>()?.highlight(_vm.corDaMarcaDoTrecho(inicio, fim))
        : null;
    return Container(
      key: const ValueKey('textoTrecho'),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
      decoration: BoxDecoration(
        color: marca ?? scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: scheme.primary, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: SingleChildScrollView(child: Text(texto, style: _estiloVersiculo(Theme.of(context).textTheme))),
    );
  }

  /// Ação do trecho: ícone num círculo e o rótulo embaixo.
  Widget _acaoTrecho(IconData icone, String rotulo, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.secondaryContainer,
              foregroundColor: scheme.onSecondaryContainer,
              child: Icon(icone),
            ),
            const SizedBox(height: 6),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// A anotação do trecho, com as tags; tocar abre a edição.
  Widget _anotacaoCard(AnotacaoTrecho anotacao, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // O card tem a cor do trecho (a da primeira tag dele): no ícone e na borda.
    final cor = _vm.corDaAnotacao(anotacao)?.cor;
    return Card(
      key: const ValueKey('anotacaoTrecho'),
      margin: const EdgeInsets.only(bottom: 12),
      color: cor == null ? scheme.surfaceContainerHigh : Color.alphaBlend(cor.withValues(alpha: 0.1), scheme.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: cor == null ? BorderSide.none : BorderSide(color: cor.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 18, color: cor ?? scheme.primary),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.of(context).translate('anotacao'), style: textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 6),
              Text(anotacao.texto, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  /// O texto renderizado (`RenderParagraph`) dentro de [objeto].
  static RenderParagraph? _paragrafo(RenderObject? objeto) {
    if (objeto is RenderParagraph) return objeto;
    RenderParagraph? achado;
    objeto?.visitChildren((filho) => achado ??= _paragrafo(filho));
    return achado;
  }

  /// Sheet com os verbetes da [palavra] no dicionário.
  /// Sheet com os verbetes da [palavra] no dicionário; com a [selecao] da palavra, mostra o marca-texto em cima.
  Future<void> _abrirPalavra(
    String palavra, {
    (({int indice, int offset}), ({int indice, int offset}))? selecao,
  }) async {
    unawaited(HapticFeedback.selectionClick());
    await DialogSheet.show<void>(
      context,
      titulo: palavra,
      conteudo: PalavraDicionarioSheet(
        viewModel: _vm,
        palavra: palavra,
        cabecalho: selecao == null || !_vm.marcaTextoDisponivel
            ? null
            : Builder(
                builder: (sheetContext) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _seletorMarcaTexto(sheetContext, selecao.$1, selecao.$2, fechar: true),
                ),
              ),
      ),
    );
  }

  /// Abre o sheet "Opções de leitura".
  Future<void> _abrirOpcoes() async {
    await DialogSheet.show<void>(
      context,
      titulo: AppLocalizations.of(context).translate('opcoesLeitura'),
      conteudo: OpcoesLeituraSheet(
        viewModel: _vm,
        onConfiguracoes: _abrirConfiguracao,
        onConfiguracoesApp: _abrirConfiguracaoApp,
      ),
    );
  }

  /// Botões anterior/próximo: vira a página com a animação; sem o livro de páginas, abre o capítulo direto.
  void _virarPagina(CapituloRef destino, {required bool frente}) {
    final paginas = _paginas;
    if (paginas == null) {
      _passarPara(destino);
    } else if (frente) {
      paginas.nextPage();
    } else {
      paginas.previousPage();
    }
  }

  /// Abre o capítulo [destino] e, se a página avançou, marca ou pergunta se marca o que ficou para trás (conforme
  /// "Ao passar a página" nas opções de leitura).
  void _passarPara(CapituloRef destino) {
    final anterior = _vm.capitulo;
    _vm.abrirCapituloCommand.execute(destino);
    if (anterior == null) return;
    switch (_vm.acaoAoPassar(anterior, destino)) {
      case MarcarAoPassar.nunca:
        break;
      case MarcarAoPassar.sempre:
        _vm.marcarAoPassarCommand.execute(anterior);
      case MarcarAoPassar.perguntar:
        _perguntarMarcar(anterior);
    }
  }

  /// Pergunta se marca como lido o capítulo [ref], que ficou para trás.
  Future<void> _perguntarMarcar(CapituloRef ref) async {
    final strings = AppLocalizations.of(context);
    // Na narração contínua a pergunta aparece ao virar a página: o áudio segue.
    _manterAudio = true;
    final marcar = await DialogSheet.show<bool>(
      context,
      titulo: _tituloCapitulo(ref),
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.translate('perguntaMarcarCapituloLido'), style: Theme.of(context).textTheme.bodyLarge),
          Builder(
            builder: (sheetContext) => DialogSheet.acoes([
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(strings.translate('agoraNao')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(strings.translate('marcarCapituloLido')),
              ),
            ]),
          ),
        ],
      ),
    );
    _manterAudio = false;
    if (marcar == true && mounted) _vm.marcarAoPassarCommand.execute(ref);
  }

  /// Leitura em páginas: um capítulo por página, na ordem da Bíblia. Arrastar a borda direita vira para o próximo
  /// capítulo e a esquerda para o anterior. A página atual é a leitura completa ([_leitura]); as vizinhas, montadas
  /// por baixo para a virada começar na hora, mostram só o texto ([_textoCapitulo]), pré-carregado.
  Widget _paginasLeitura(AppLocalizations strings) {
    final ref = _vm.capitulo!;
    final sequencia = _vm.sequencia;
    final pagina = sequencia.indexOf(ref);
    if (pagina < 0) return _leitura(strings);

    final paginas = _paginas ??= PageCurlController(initialPage: pagina);
    // Capítulo aberto por fora das páginas (ex.: histórico): vai direto para ele, sem a animação.
    if (paginas.page != pagina && !paginas.isTurning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !paginas.isTurning && paginas.page != pagina) paginas.jumpToPage(pagina);
      });
    }

    return PageCurlView(
      // Outra versão tem outra sequência de capítulos: recomeça o livro.
      key: ValueKey(_vm.versao?.versaId),
      controller: paginas,
      itemCount: sequencia.length,
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      onPageChanged: (index) {
        final destino = sequencia[index];
        if (destino != _vm.capitulo) _passarPara(destino);
      },
      itemBuilder: (context, index) {
        final capitulo = sequencia[index];
        if (capitulo == _vm.capitulo) return _leitura(strings);
        _vm.precarregar(capitulo);
        return _textoCapitulo(capitulo);
      },
    );
  }

  /// Página vizinha: só o texto do capítulo, com o mesmo layout da leitura (sem marcações nem destaque).
  Widget _textoCapitulo(CapituloRef ref) {
    final versiculos = _vm.textoDe(ref);
    if (versiculos == null) return const Center(child: CircularProgressIndicator());

    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, _espacoNavegacao),
      itemCount: versiculos.length + 1,
      itemBuilder: (_, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${_vm.versao?.versaNome ?? ''} · ${_tituloCapitulo(ref)}', style: textTheme.labelLarge),
          );
        }
        final versiculo = versiculos[index - 1];
        return Padding(
          // Mesmo recuo da leitura: a linha do versículo e, com login, a coluna dos ícones (40).
          padding: EdgeInsets.fromLTRB(4, 6, _vm.logado ? 44 : 4, 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${versiculo.versNumero}  ',
                  style: textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                ),
                ..._textoMarcado(
                  versiculo,
                  _estiloVersiculo(textTheme),
                  _vm.marcasDe(ref),
                  anotados: _vm.trechosAnotados(ref, index - 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final carregando = _vm.carregarCommand.running && _vm.indice == null;
    final lendo = _vm.capitulo != null;

    // Outro capítulo (ou o índice): AppBar no tamanho normal e navegação visível.
    if (_vm.capitulo != _capituloMontado) {
      _capituloMontado = _vm.capitulo;
      _barra = _EstadoBarra.normal;
      _navegacaoVisivel = true;
      _textoKeys.clear();
      _selecaoAncora = null;
      _selecaoFoco = null;
      _mostrarNavegacao?.cancel();
    }

    final Widget body;
    if (carregando) {
      body = const Loading();
    } else if (_vm.indice == null) {
      body = _erroCarregamento(strings);
    } else if (lendo) {
      body = _paginasLeitura(strings);
    } else {
      // De volta ao índice: o próximo capítulo aberto cria o livro de páginas já na página certa.
      _paginas = null;
      body = _indice(strings);
    }

    // Voltar no capítulo aberto pelo índice fecha o capítulo; senão sai da tela (para a home, se for a primeira).
    final saiDaTela = !lendo || _vm.abertaPorDestino;
    final semTelaAnterior = _semTelaAnterior;
    return PopScope(
      canPop: saiDaTela && !semTelaAnterior,
      onPopInvokedWithResult: (didPop, _) {
        // Saiu da leitura: o brilho volta ao do sistema já, sem esperar a animação de saída.
        if (didPop) {
          _vm.pararNarracaoAoSair();
          unawaited(_vm.sairDaLeitura());
          return;
        }
        if (saiDaTela) {
          _irParaHome();
        } else {
          _vm.fecharCapitulo();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // A AppBar fica no corpo (e não em `Scaffold.appBar`) para encolher animada sem remontar a leitura.
        body: Column(
          children: [
            _appBarAnimada(strings),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: lendo ? NotificationListener<ScrollNotification>(onNotification: _aoRolar, child: body) : body,
              ),
            ),
          ],
        ),
        floatingActionButton: lendo && _vm.indice != null
            ? IgnorePointer(
                ignoring: !_navegacaoVisivel,
                child: AnimatedSlide(
                  offset: _navegacaoVisivel ? Offset.zero : const Offset(0, 1.5),
                  duration: _duracaoBarra,
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _navegacaoVisivel ? 1 : 0,
                    duration: _duracaoBarra,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([_paginas]),
                      builder: (context, _) => _navegacaoLeitura(strings),
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, child) => _screen());
  }
}

/// AppBar da leitura: normal, compacta (desceu o texto) ou oculta (desceu mais; fica só a alça).
enum _EstadoBarra { normal, compacta, oculta }

/// Ação escolhida no sheet do trecho que abre outro sheet.
enum _AcaoTrecho { compartilhar, anotar }
