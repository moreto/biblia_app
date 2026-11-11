import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/livro_model.dart';
import '../../../../data/model/biblia/versiculo_texto_model.dart';
import '../use_case/biblia_leitura_usecase.dart';
import '../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import 'biblia_leitura_viewmodel.dart';
import 'widgets/capitulo_chip.dart';
import 'widgets/historico_leitura_sheet.dart';
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
/// - AppBar: histórico de leitura, orientação da tela e tema.
/// - Aberta com destino (`/biblia-leitura?versaId=&livrId=&capiNumero=&versNumero=`, ex.: versículo de um renomado):
///   abre direto no capítulo, na versão do destino, rola até o versículo e o destaca; voltar sai da tela.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeLeitura], [iconeHistorico], [iconeVersao], [iconeAnterior],
/// [iconeProximo], [iconeLido], [iconeNaoLido], [iconeParcial], [iconeComentarIndicar], [iconeIndicadoSemComentario],
/// [iconeComentado], [iconeIndicar],
/// [iconeIndicado], [iconeRemover] e [iconeTentarNovamente].
class BibliaLeituraView extends StatefulWidget {
  const BibliaLeituraView({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  /// Ícone do menu da leitura e do índice vazio.
  static const iconeLeitura = 'book-open-variant';

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

  @override
  State<BibliaLeituraView> createState() => _BibliaLeituraViewState();
}

class _BibliaLeituraViewState extends State<BibliaLeituraView> {
  BibliaLeituraViewmodel get _vm => widget.viewModel;

  /// Versículo do destino para onde rolar depois de montar a lista, e a chave da linha dele.
  int? _rolarPara;
  final GlobalKey _alvoKey = GlobalKey();

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
  ];

  @override
  void initState() {
    super.initState();
    for (final command in _comandos(_vm)) {
      command.addListener(_onResult);
    }
  }

  @override
  void didUpdateWidget(covariant BibliaLeituraView oldWidget) {
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
    super.dispose();
  }

  void _onResult() {
    for (final Command command in [_vm.versaoCommand, _vm.marcarLidoCommand, _vm.marcarVersiculoCommand]) {
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

  PreferredSizeWidget _appBar(AppLocalizations strings) {
    final ref = _vm.capitulo;
    return AppBar(
      leading: ref == null || _vm.abertaPorDestino
          ? null
          : IconButton(
              tooltip: strings.translate('voltar'),
              onPressed: _vm.fecharCapitulo,
              icon: const Icon(Icons.arrow_back),
            ),
      title: Text(ref == null ? strings.translate('leituraBiblica') : _tituloCapitulo(ref)),
      actions: [
        IconButton(
          tooltip: strings.translate('historicoLeitura'),
          onPressed: _vm.indice == null ? null : _abrirHistorico,
          icon: BibliaLeituraView.icone(BibliaLeituraView.iconeHistorico, Icons.history),
        ),
        const OrientationButton(),
        const ThemeModeButton(),
      ],
    );
  }

  /// Seleção da versão (`/v1/versao`), no topo do índice, logo acima do filtro de testamentos.
  Widget _versaoSelecao(AppLocalizations strings) {
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${progresso.completos}/${progresso.total} ${strings.translate('capitulosLidos')}'
            '${progresso.emAndamento > 0 ? ' · ${progresso.emAndamento} ${strings.translate('emAndamento')}' : ''}',
          ),
          const SizedBox(height: 4),
          // Avança por versículo lido, para a leitura parcial também aparecer na barra.
          LinearProgressIndicator(value: progresso.fracao),
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

    return ListView.builder(
      // Enquanto há rolagem pendente, monta o capítulo inteiro para a linha do versículo existir.
      scrollCacheExtent: _rolarPara != null ? const ScrollCacheExtent.pixels(100000) : null,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          key: versiculo.versId == _rolarPara ? _alvoKey : null,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _vm.destacarVersiculo(versiculo.versId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _vm.versiculoDestacado == versiculo.versId ? _corDestaque() : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${versiculo.versNumero}  ',
                            style: textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: versiculo.versTexto, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

  Widget _barraLeitura(AppLocalizations strings) {
    final anterior = _vm.anterior;
    final proximo = _vm.proximo;
    final lido = _vm.lidoAtual?.completo ?? false;
    final marcando = _vm.marcarLidoCommand.running;

    return BottomAppBar(
      child: Row(
        children: [
          IconButton(
            tooltip: strings.translate('capituloAnterior'),
            onPressed: anterior == null ? null : () => _vm.abrirCapituloCommand.execute(anterior),
            icon: BibliaLeituraView.icone(BibliaLeituraView.iconeAnterior, Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: marcando || _vm.versiculos == null ? null : _vm.marcarLidoCommand.execute,
                icon: marcando
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : BibliaLeituraView.icone(
                        lido ? BibliaLeituraView.iconeLido : BibliaLeituraView.iconeNaoLido,
                        lido ? Icons.check_circle : Icons.check_circle_outline,
                      ),
                label: Text(strings.translate(lido ? 'desmarcarCapituloLido' : 'marcarCapituloLido')),
              ),
            ),
          ),
          IconButton(
            tooltip: strings.translate('proximoCapitulo'),
            onPressed: proximo == null ? null : () => _vm.abrirCapituloCommand.execute(proximo),
            icon: BibliaLeituraView.icone(BibliaLeituraView.iconeProximo, Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final carregando = _vm.carregarCommand.running && _vm.indice == null;
    final lendo = _vm.capitulo != null;

    final Widget body;
    if (carregando) {
      body = const Loading();
    } else if (_vm.indice == null) {
      body = _erroCarregamento(strings);
    } else if (lendo) {
      body = _leitura(strings);
    } else {
      body = _indice(strings);
    }

    return PopScope(
      canPop: !lendo || _vm.abertaPorDestino,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && lendo) _vm.fecharCapitulo();
      },
      child: Scaffold(
        appBar: _appBar(strings),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: body,
        bottomNavigationBar: lendo && _vm.indice != null ? _barraLeitura(strings) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, child) => _screen());
  }
}
