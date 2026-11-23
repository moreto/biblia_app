import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../data/model/biblia/capitulo_lido_model.dart';
import '../../../routing/routes.dart';
import '../use_case/historico_leitura_usecase.dart';
import 'historico_leitura_viewmodel.dart';

/// Tela "Histórico de leitura" (`Routes.historicoLeitura`, tela própria, não é aba; item do menu Bíblia): capítulos
/// que o usuário leu na versão escolhida (`GET /v1/versiculo-reacao/lidos/:versaId`), do mais recente para o mais
/// antigo.
///
/// - Topo: seleção da versão (`/v1/versao`), a mesma da leitura; trocar aqui também troca lá.
/// - Resumo: capítulos concluídos, em andamento e versículos lidos na versão.
/// - "Continuar leitura": o capítulo em andamento lido mais recentemente; tocar abre a leitura nele.
/// - Filtros "Todos", "Concluídos" e "Em andamento", com a quantidade de cada um.
/// - Lista agrupada por dia (hoje, ontem, data e "Sem data"); cada capítulo mostra o livro e o número, a barra de
///   progresso e os versículos lidos. Tocar abre o capítulo em `Routes.bibliaLeitura`, na versão do histórico.
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida e
///   erros (atualizar, puxar para baixo ou trocar a versão) viram SnackBar.
/// - Ao voltar da leitura, o histórico é recarregado (o usuário pode ter marcado capítulos).
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeHistorico], [iconeVersao], [iconeConcluido], [iconeEmAndamento],
/// [iconeVersiculos], [iconeTodos], [iconeContinuar], [iconeHoje], [iconeDia], [iconeSemData], [iconeAbrir] e
/// [iconeAtualizar].
class HistoricoLeituraView extends StatefulWidget {
  const HistoricoLeituraView({super.key, required this.viewModel});

  final HistoricoLeituraViewmodel viewModel;

  /// Ícone da tela (`menu_icone` e `func_icone` de /historico-leitura) e da lista vazia.
  static const iconeHistorico = 'book-clock-outline';
  static const iconeVersao = 'book-multiple';

  /// Capítulo concluído (o mesmo da leitura).
  static const iconeConcluido = 'check-circle';

  /// Capítulo com parte dos versículos lidos (o mesmo da leitura).
  static const iconeEmAndamento = 'progress-check';
  static const iconeVersiculos = 'format-list-checks';
  static const iconeTodos = 'format-list-bulleted';
  static const iconeContinuar = 'book-arrow-right-outline';
  static const iconeHoje = 'calendar-today';
  static const iconeDia = 'calendar-blank-outline';
  static const iconeSemData = 'calendar-question';
  static const iconeAbrir = 'chevron-right';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Ícone de cada filtro.
  static String iconeFiltro(HistoricoFiltro filtro) => switch (filtro) {
    HistoricoFiltro.todos => iconeTodos,
    HistoricoFiltro.concluidos => iconeConcluido,
    HistoricoFiltro.emAndamento => iconeEmAndamento,
  };

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  @override
  State<HistoricoLeituraView> createState() => _HistoricoLeituraViewState();
}

class _HistoricoLeituraViewState extends State<HistoricoLeituraView> {
  HistoricoLeituraViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.carregarCommand.addListener(_onCarregar);
    _vm.versaoCommand.addListener(_onVersao);
  }

  @override
  void didUpdateWidget(covariant HistoricoLeituraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.carregarCommand.removeListener(_onCarregar);
    oldWidget.viewModel.versaoCommand.removeListener(_onVersao);
    _vm.carregarCommand.addListener(_onCarregar);
    _vm.versaoCommand.addListener(_onVersao);
  }

  @override
  void dispose() {
    _vm.carregarCommand.removeListener(_onCarregar);
    _vm.versaoCommand.removeListener(_onVersao);
    super.dispose();
  }

  /// Erro de uma atualização (com histórico já carregado) vira SnackBar; o do primeiro carregamento fica na tela.
  void _onCarregar() {
    if (_vm.historico == null) return;
    _mostrarErro(_vm.carregarCommand.result, _vm.carregarCommand.error, _vm.carregarCommand.clearResult);
  }

  void _onVersao() => _mostrarErro(_vm.versaoCommand.result, _vm.versaoCommand.error, _vm.versaoCommand.clearResult);

  void _mostrarErro(Result? result, bool erro, VoidCallback limpar) {
    if (!mounted || !erro) return;
    final mensagem = HistoricoLeituraView.mensagemErro(result);
    limpar();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  /// Abre o capítulo na leitura e, ao voltar, recarrega o histórico.
  Future<void> _abrirLeitura(CapituloLidoModel capitulo) async {
    final destino = _vm.destino(capitulo);
    if (destino == null) return;
    await context.push(Uri(path: Routes.bibliaLeitura, queryParameters: destino.toQuery()).toString());
    if (mounted && !_vm.carregarCommand.running) _vm.carregarCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final historico = _vm.historico;

    final Widget body;
    if (historico == null && !command.error) {
      body = const Loading();
    } else if (historico == null) {
      body = _erroCarregamento(strings);
    } else {
      body = _conteudo(historico, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('historicoLeitura')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: command.running || _vm.versaoCommand.running ? null : command.execute,
            icon: HistoricoLeituraView.icone(HistoricoLeituraView.iconeAtualizar, Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
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
            Text(strings.translate(HistoricoLeituraView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: HistoricoLeituraView.icone(HistoricoLeituraView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(List<CapituloLidoModel> historico, AppLocalizations strings) {
    final continuar = _vm.continuar;
    final grupos = _vm.grupos;

    final itens = <Widget>[
      if (_vm.versoes.isNotEmpty) _versaoSelecao(strings),
      if (historico.isEmpty)
        _vazio(strings.translate('nenhumaLeituraRegistrada'))
      else ...[
        _resumo(strings),
        if (continuar != null) _continuar(continuar, strings),
        _filtros(strings),
        if (grupos.isEmpty) _vazio(strings.translate('nenhumCapituloNoFiltro')),
        for (final grupo in grupos) ...[
          _cabecalhoGrupo(grupo, strings),
          for (final capitulo in grupo.capitulos) _capitulo(capitulo, strings),
        ],
      ],
    ];

    return Column(
      children: [
        if (_vm.carregarCommand.running || _vm.versaoCommand.running) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _vm.carregarCommand.execute,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: itens.length,
              itemBuilder: (context, index) => itens[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _versaoSelecao(AppLocalizations strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<int>(
        key: ValueKey(_vm.versao?.versaId),
        initialValue: _vm.versao?.versaId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('versao'),
          prefixIcon: HistoricoLeituraView.icone(HistoricoLeituraView.iconeVersao, Icons.library_books_outlined),
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

  Widget _vazio(String mensagem) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          HistoricoLeituraView.icone(
            HistoricoLeituraView.iconeHistorico,
            Icons.history,
            size: 48,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _resumo(AppLocalizations strings) {
    final resumo = _vm.resumo;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            _indicador(
              HistoricoLeituraView.iconeConcluido,
              Icons.check_circle,
              resumo.concluidos,
              strings.translate('capitulosConcluidos'),
            ),
            _indicador(
              HistoricoLeituraView.iconeEmAndamento,
              Icons.timelapse,
              resumo.emAndamento,
              strings.translate('capitulosEmAndamento'),
            ),
            _indicador(
              HistoricoLeituraView.iconeVersiculos,
              Icons.checklist,
              resumo.versiculos,
              strings.translate('versiculosLidos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicador(String icone, IconData fallback, int valor, String rotulo) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          HistoricoLeituraView.icone(icone, fallback, color: scheme.primary),
          const SizedBox(height: 4),
          Text('$valor', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(
            rotulo,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _continuar(CapituloLidoModel capitulo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      color: scheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirLeitura(capitulo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              HistoricoLeituraView.icone(
                HistoricoLeituraView.iconeContinuar,
                Icons.auto_stories,
                size: 32,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.translate('continuarLeitura'),
                      style: textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${capitulo.livrNome} ${capitulo.capiNumero}',
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _vm.fracao(capitulo), borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 4),
                    Text(
                      '${capitulo.versLidos}/${capitulo.versTotal} ${strings.translate('versiculosLidos')}',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              HistoricoLeituraView.icone(
                HistoricoLeituraView.iconeAbrir,
                Icons.chevron_right,
                color: scheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtros(AppLocalizations strings) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          for (final filtro in HistoricoFiltro.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: HistoricoLeituraView.icone(
                  HistoricoLeituraView.iconeFiltro(filtro),
                  Icons.filter_list,
                  size: 18,
                ),
                label: Text('${strings.translate(filtro.chave)} (${_vm.quantidade(filtro)})'),
                selected: _vm.filtro == filtro,
                showCheckmark: false,
                onSelected: (_) => _vm.selecionarFiltro(filtro),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecalhoGrupo(GrupoHistorico grupo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final chave = grupo.chave;
    final dia = grupo.dia;
    final titulo = chave != null
        ? strings.translate(chave)
        : dia == null
        ? ''
        : MaterialLocalizations.of(context).formatFullDate(dia);
    final (icone, fallback) = switch (grupo.periodo) {
      PeriodoHistorico.hoje => (HistoricoLeituraView.iconeHoje, Icons.today),
      PeriodoHistorico.semData => (HistoricoLeituraView.iconeSemData, Icons.event_busy),
      _ => (HistoricoLeituraView.iconeDia, Icons.calendar_today_outlined),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          HistoricoLeituraView.icone(icone, fallback, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${grupo.capitulos.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _capitulo(CapituloLidoModel capitulo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final lidoEm = capitulo.lidoEm;
    final hora = lidoEm == null
        ? ''
        : ' · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(lidoEm.toLocal()))}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirLeitura(capitulo),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              HistoricoLeituraView.icone(
                capitulo.completo ? HistoricoLeituraView.iconeConcluido : HistoricoLeituraView.iconeEmAndamento,
                capitulo.completo ? Icons.check_circle : Icons.timelapse,
                color: scheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${capitulo.livrNome} ${capitulo.capiNumero}',
                      style: textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: _vm.fracao(capitulo), borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 4),
                    Text(
                      '${capitulo.versLidos}/${capitulo.versTotal} ${strings.translate('versiculosLidos')}$hora',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.translate('abrirNaLeitura'),
                onPressed: () => _abrirLeitura(capitulo),
                icon: HistoricoLeituraView.icone(HistoricoLeituraView.iconeAbrir, Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
