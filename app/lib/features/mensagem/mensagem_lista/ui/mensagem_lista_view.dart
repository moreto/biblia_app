import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../data/model/mensagem/mensagem_recebida_model.dart';
import '../use_case/mensagem_lista_usecase.dart';
import 'mensagem_lista_viewmodel.dart';
import 'widgets/mensagem_detalhe_dialog.dart';

/// Ações do menu de cada mensagem.
enum _Acao { lida, arquivar }

/// Tela "Mensagens" (`Routes.mensagemLista`, tela própria, não é aba): mensagens que o usuário recebeu
/// (`/v1/mensagem-usuario/recebidas`), mais recentes primeiro.
///
/// - Topo: filtro "Caixa de entrada" (não arquivadas), "Não lidas" (com a quantidade) e "Arquivadas".
/// - Cada mensagem mostra o ícone (sistema ou usuário; fechado se não lida), título (negrito se não lida),
///   remetente ("Sistema" nas de sistema) e data, e o começo do texto. Tocar abre o [MensagemDetalheDialog] e marca
///   como lida; o menu marca como lida/não lida e arquiva/desarquiva.
/// - Primeiro carregamento: progresso; se falhar, "Tentar novamente". Depois disso a lista é mantida; erro de
///   atualização ou de gravação vira SnackBar.
/// - Vazio: `nenhumaMensagemRecebida` (entrada), `nenhumaMensagemNaoLida`, `nenhumaMensagemArquivada`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeNaoLida], [iconeLida], [iconeSistema], [iconeLer], [iconeArquivar],
/// [iconeDesarquivar], [iconeAcoes], [iconeAtualizar] e o [MensagemFiltro.icone] de cada filtro.
class MensagemListaView extends StatefulWidget {
  const MensagemListaView({super.key, required this.viewModel});

  final MensagemListaViewmodel viewModel;

  static const iconeNaoLida = 'email-outline';
  static const iconeLida = 'email-open-outline';

  /// Mensagem de sistema (avisos e e-mails do app).
  static const iconeSistema = 'bell-outline';

  /// "Marcar como lida" no menu; "não lida" usa [iconeMarcarNaoLida].
  static const iconeLer = 'email-check-outline';
  static const iconeMarcarNaoLida = 'email-mark-as-unread';
  static const iconeArquivar = 'archive-outline';
  static const iconeDesarquivar = 'archive-arrow-up-outline';
  static const iconeAcoes = 'dots-vertical';
  static const iconeAtualizar = 'refresh';

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
  State<MensagemListaView> createState() => _MensagemListaViewState();
}

class _MensagemListaViewState extends State<MensagemListaView> {
  MensagemListaViewmodel get _vm => widget.viewModel;

  List<Command> _comandos(MensagemListaViewmodel vm) => [
    vm.carregarCommand,
    vm.abrirCommand,
    vm.lidaCommand,
    vm.arquivarCommand,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _comandos(_vm)) {
      c.addListener(_onResult);
    }
  }

  @override
  void didUpdateWidget(covariant MensagemListaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final c in _comandos(oldWidget.viewModel)) {
      c.removeListener(_onResult);
    }
    for (final c in _comandos(_vm)) {
      c.addListener(_onResult);
    }
  }

  @override
  void dispose() {
    for (final c in _comandos(_vm)) {
      c.removeListener(_onResult);
    }
    super.dispose();
  }

  /// Erros de atualização (com lista já carregada) e de gravação viram SnackBar.
  void _onResult() {
    if (!mounted) return;
    for (final command in _comandos(_vm)) {
      if (!command.error) continue;
      if (command == _vm.carregarCommand && _vm.mensagens == null) continue;
      final mensagem = MensagemListaView.mensagemErro(command.result);
      command.clearResult();
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
    }
  }

  void _abrir(MensagemRecebidaModel mensagem) {
    _vm.abrirCommand.execute(mensagem);
    MensagemDetalheDialog.show(context, viewModel: _vm, musuId: mensagem.musuId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final mensagens = _vm.mensagens;

    final Widget body;
    if (mensagens == null && !command.error) {
      body = const Loading();
    } else if (mensagens == null) {
      body = _erroCarregamento(strings);
    } else {
      final filtradas = _vm.filtradas;
      body = Column(
        children: [
          if (command.running || _vm.gravando) const LinearProgressIndicator(),
          _filtros(strings),
          Expanded(
            child: RefreshIndicator(
              onRefresh: command.execute,
              child: filtradas.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: constraints.maxHeight, child: _vazio(strings)),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtradas.length,
                      itemBuilder: (context, index) => _mensagem(filtradas[index], strings),
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('mensagens')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: command.running ? null : command.execute,
            icon: MensagemListaView.icone(MensagemListaView.iconeAtualizar, Icons.refresh),
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
    final naoLidas = _vm.naoLidas;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filtro in MensagemFiltro.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _vm.filtro == filtro,
                  onSelected: (_) => _vm.selecionarFiltro(filtro),
                  avatar: MensagemListaView.icone(filtro.icone, Icons.mail_outline, size: 18),
                  label: Text(
                    filtro == MensagemFiltro.naoLidas && naoLidas > 0
                        ? '${strings.translate(filtro.rotulo)} ($naoLidas)'
                        : strings.translate(filtro.rotulo),
                  ),
                ),
              ),
          ],
        ),
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
            Text(strings.translate(MensagemListaView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: MensagemListaView.icone(MensagemListaView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final texto = switch (_vm.filtro) {
      MensagemFiltro.entrada => 'nenhumaMensagemRecebida',
      MensagemFiltro.naoLidas => 'nenhumaMensagemNaoLida',
      MensagemFiltro.arquivadas => 'nenhumaMensagemArquivada',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MensagemListaView.icone(_vm.filtro.icone, Icons.inbox_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(strings.translate(texto), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _mensagem(MensagemRecebidaModel mensagem, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final naoLida = !mensagem.musuLida;
    final remetente = _vm.remetente(mensagem) ?? strings.translate('sistema');
    final data = _vm.data(mensagem.recebidaEm);
    final secundario = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final habilitado = !_vm.gravando;

    final icone = mensagem.sistema
        ? MensagemListaView.iconeSistema
        : (naoLida ? MensagemListaView.iconeNaoLida : MensagemListaView.iconeLida);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? () => _abrir(mensagem) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Badge(
                isLabelVisible: naoLida,
                smallSize: 10,
                child: CircleAvatar(
                  backgroundColor: naoLida ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                  child: MensagemListaView.icone(
                    icone,
                    Icons.mail_outline,
                    color: naoLida ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mensagem.mensTitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(fontWeight: naoLida ? FontWeight.bold : null),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [remetente, ?data].join(' · '),
                      style: secundario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _vm.resumo(mensagem),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: habilitado,
                icon: MensagemListaView.icone(MensagemListaView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.lida => _vm.lidaCommand.execute(mensagem),
                  _Acao.arquivar => _vm.arquivarCommand.execute(mensagem),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _Acao.lida,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: naoLida
                          ? MensagemListaView.icone(MensagemListaView.iconeLer, Icons.mark_email_read_outlined)
                          : MensagemListaView.icone(
                              MensagemListaView.iconeMarcarNaoLida,
                              Icons.mark_email_unread_outlined,
                            ),
                      title: Text(strings.translate(naoLida ? 'marcarComoLida' : 'marcarComoNaoLida')),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Acao.arquivar,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: mensagem.musuArquivada
                          ? MensagemListaView.icone(MensagemListaView.iconeDesarquivar, Icons.unarchive_outlined)
                          : MensagemListaView.icone(MensagemListaView.iconeArquivar, Icons.archive_outlined),
                      title: Text(strings.translate(mensagem.musuArquivada ? 'desarquivar' : 'arquivar')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
