import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../data/model/fale_conosco/fale_conosco_atendimento_model.dart';
import 'fale_conosco_atendimento_viewmodel.dart';
import 'widgets/fale_conosco_atendimento_detalhe_dialog.dart';

/// Tela "Atendimento do Fale conosco" (`Routes.faleConoscoAtendimento`, tela própria, não é aba): fila de chamados
/// para o atendimento responder (`/v1/fale-conosco`). O app não restringe a tela: quem a vê será definido pelo perfil
/// no menu. Se a API recusar o acesso (403 `acessoNegado`), a mensagem aparece no lugar da fila.
///
/// - Topo: filtro por situação ("Todas" ou uma situação da configuração `faleConoscoStatus`) e "Meus chamados"
///   (responsável = usuário logado).
/// - Cada chamado mostra a prioridade (faixa colorida: quanto mais alta na configuração, mais forte), assunto,
///   protocolo, quem enviou (nome e e-mail), categoria, situação, data de envio, responsável e o tempo até a primeira
///   resposta. Fechados ficam esmaecidos. Tocar abre o [FaleConoscoAtendimentoDetalheDialog].
/// - Primeiro carregamento: progresso; se falhar, mensagem e "Tentar novamente". Depois disso a fila é mantida; erro
///   de atualização vira SnackBar. Vazio: `nenhumChamadoNaFila`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeTela], [iconeTodas], [iconeMeus], [iconePrioridade], [iconeResponsavel],
/// [iconeTempo], [iconeFechado] e [iconeAtualizar]; o detalhe usa os seus.
class FaleConoscoAtendimentoView extends StatefulWidget {
  const FaleConoscoAtendimentoView({super.key, required this.viewModel});

  final FaleConoscoAtendimentoViewmodel viewModel;

  /// Tela (vazio e erro); também o ícone sugerido para o menu de /fale-conosco-atendimento.
  static const iconeTela = 'face-agent';
  static const iconeTodas = 'inbox-multiple-outline';
  static const iconeMeus = 'account-check-outline';
  static const iconePrioridade = 'flag-outline';
  static const iconeResponsavel = 'account-tie-outline';
  static const iconeTempo = 'timer-outline';
  static const iconeFechado = 'lock-outline';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(FaleConoscoAtendimentoViewmodel vm, Result? result) => switch (result) {
    Error(error: final error) => vm.mensagemErro(error),
    _ => kDefaultAppError,
  };

  /// Cores da prioridade pelo nível (0 = menor, 1 = maior na configuração).
  static (Color fundo, Color texto) coresPrioridade(ColorScheme scheme, double? nivel) => switch (nivel) {
    null => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    >= 1 => (scheme.errorContainer, scheme.onErrorContainer),
    >= 0.5 => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    _ => (scheme.secondaryContainer, scheme.onSecondaryContainer),
  };

  @override
  State<FaleConoscoAtendimentoView> createState() => _FaleConoscoAtendimentoViewState();
}

class _FaleConoscoAtendimentoViewState extends State<FaleConoscoAtendimentoView> {
  FaleConoscoAtendimentoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.carregarCommand.addListener(_onCarregar);
  }

  @override
  void didUpdateWidget(covariant FaleConoscoAtendimentoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.carregarCommand.removeListener(_onCarregar);
    _vm.carregarCommand.addListener(_onCarregar);
  }

  @override
  void dispose() {
    _vm.carregarCommand.removeListener(_onCarregar);
    super.dispose();
  }

  /// Erro de atualização (com fila já carregada) vira SnackBar.
  void _onCarregar() {
    final command = _vm.carregarCommand;
    if (!mounted || !command.error || _vm.fila == null) return;
    final mensagem = FaleConoscoAtendimentoView.mensagemErro(_vm, command.result);
    command.clearResult();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final fila = _vm.fila;

    final Widget body;
    if (fila == null && !command.error) {
      body = const Loading();
    } else if (fila == null) {
      body = _erroCarregamento(strings);
    } else {
      body = Column(
        children: [
          if (command.running) const LinearProgressIndicator() else const SizedBox(height: 4),
          _filtros(strings),
          Expanded(
            child: RefreshIndicator(
              onRefresh: command.execute,
              child: fila.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: constraints.maxHeight, child: _vazio(strings)),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: fila.length,
                      itemBuilder: (context, index) => _chamado(fila[index], strings),
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('atendimentoFaleConosco')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: command.running ? null : command.execute,
            icon: FaleConoscoAtendimentoView.icone(FaleConoscoAtendimentoView.iconeAtualizar, Icons.refresh),
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

  Widget _filtros(AppLocalizations strings) {
    final filtro = _vm.filtro;
    Widget chip(Widget child) => Padding(padding: const EdgeInsets.only(right: 8), child: child);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(
              FilterChip(
                selected: filtro.meus,
                onSelected: (_) => _vm.alternarMeus(),
                avatar: filtro.meus
                    ? null
                    : FaleConoscoAtendimentoView.icone(
                        FaleConoscoAtendimentoView.iconeMeus,
                        Icons.person_outline,
                        size: 18,
                      ),
                label: Text(strings.translate('meusChamados')),
              ),
            ),
            chip(
              ChoiceChip(
                selected: filtro.situacao == null,
                onSelected: (_) => _vm.selecionarSituacao(null),
                avatar: FaleConoscoAtendimentoView.icone(FaleConoscoAtendimentoView.iconeTodas, Icons.inbox, size: 18),
                label: Text(strings.translate('todas')),
              ),
            ),
            for (final s in _vm.opcoes.situacoes)
              chip(
                ChoiceChip(
                  selected: filtro.situacao == s.chave,
                  onSelected: (_) => _vm.selecionarSituacao(s.chave),
                  label: Text(strings.translate(s.rotulo)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.carregarCommand;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaleConoscoAtendimentoView.icone(
              FaleConoscoAtendimentoView.iconeTela,
              Icons.support_agent,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              strings.translate(FaleConoscoAtendimentoView.mensagemErro(_vm, command.result)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: FaleConoscoAtendimentoView.icone(FaleConoscoAtendimentoView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaleConoscoAtendimentoView.icone(
              FaleConoscoAtendimentoView.iconeTodas,
              Icons.inbox,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumChamadoNaFila'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _chamado(FaleConoscoAtendimentoModel chamado, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final (fundoPrioridade, textoPrioridade) = FaleConoscoAtendimentoView.coresPrioridade(
      scheme,
      _vm.nivelPrioridade(chamado.fconPrioridade),
    );
    final enviado = _vm.data(chamado.createdAt);
    final tempo = _vm.duracao(chamado.fconTempoResposta);
    final responsavel = chamado.fconResponsavelNome?.trim();

    Widget info(String icone, IconData fallback, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaleConoscoAtendimentoView.icone(icone, fallback, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(texto, style: secundario, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    return Opacity(
      opacity: chamado.fechado ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => FaleConoscoAtendimentoDetalheDialog.show(context, viewModel: _vm, chamado: chamado),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: fundoPrioridade),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                chamado.fconAssunto,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (chamado.fechado) ...[
                              const SizedBox(width: 8),
                              FaleConoscoAtendimentoView.icone(
                                FaleConoscoAtendimentoView.iconeFechado,
                                Icons.lock_outline,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${chamado.fconNome} · ${chamado.fconEmail}',
                          style: textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ['${strings.translate('protocolo')} ${chamado.fconProtocolo}', ?enviado].join(' · '),
                          style: secundario,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _etiqueta(
                              strings.translate(_vm.prioridade(chamado.fconPrioridade)),
                              fundo: fundoPrioridade,
                              cor: textoPrioridade,
                              icone: FaleConoscoAtendimentoView.iconePrioridade,
                            ),
                            _etiqueta(
                              strings.translate(_vm.situacao(chamado.fconStatus)),
                              fundo: scheme.secondaryContainer,
                              cor: scheme.onSecondaryContainer,
                            ),
                            _etiqueta(
                              strings.translate(_vm.categoria(chamado.fconCategoria)),
                              fundo: scheme.surfaceContainerHighest,
                              cor: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            info(
                              FaleConoscoAtendimentoView.iconeResponsavel,
                              Icons.badge_outlined,
                              (responsavel?.isNotEmpty ?? false) ? responsavel! : strings.translate('semResponsavel'),
                            ),
                            info(
                              FaleConoscoAtendimentoView.iconeTempo,
                              Icons.timer_outlined,
                              tempo == null
                                  ? strings.translate('semResposta')
                                  : '${strings.translate('primeiraResposta')}: $tempo',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto, {required Color fundo, required Color cor, String? icone}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          FaleConoscoAtendimentoView.icone(icone, Icons.flag_outlined, size: 12, color: cor),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
          ),
        ),
      ],
    ),
  );
}
