import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../data/model/fale_conosco/fale_conosco_model.dart';
import 'fale_conosco_viewmodel.dart';
import 'widgets/fale_conosco_detalhe_dialog.dart';
import 'widgets/fale_conosco_form_dialog.dart';

/// Tela "Fale conosco" (`Routes.faleConosco`, tela própria, não é aba): chamados que o usuário abriu
/// (`/v1/fale-conosco/meus`), mais recentes primeiro, e o envio de uma nova mensagem.
///
/// - Cada chamado mostra o assunto, o protocolo, a categoria, a situação (rótulos das configurações
///   `faleConoscoCategoria` e `faleConoscoStatus`), a data de envio e se já foi respondido ou fechado. Tocar abre o
///   [FaleConoscoDetalheDialog], com a conversa e o campo para responder.
/// - Parte inferior: "Nova mensagem" ao lado de "Voltar" abre o [FaleConoscoFormDialog]; ao enviar, SnackBar com o
///   protocolo (`chamadoEnviado`).
/// - Primeiro carregamento: progresso; se falhar, "Tentar novamente". Depois disso a lista é mantida; erro de
///   atualização vira SnackBar. Vazio: `nenhumChamado`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeTela], [iconeNova], [iconeChamado], [iconeAguardando], [iconeRespondido],
/// [iconeFechado], [iconeCategoria] e [iconeAtualizar]; o formulário e o detalhe usam os seus.
class FaleConoscoView extends StatefulWidget {
  const FaleConoscoView({super.key, required this.viewModel});

  final FaleConoscoViewmodel viewModel;

  /// Tela (vazio; também `func_icone` de /fale-conosco) e mensagens do atendimento no detalhe.
  static const iconeTela = 'face-agent';

  /// Botão "Nova mensagem" e título do formulário.
  static const iconeNova = 'email-plus-outline';
  static const iconeChamado = 'ticket-outline';

  /// Situação do card: sem resposta, respondido e fechado.
  static const iconeAguardando = 'progress-clock';
  static const iconeRespondido = 'message-reply-text-outline';
  static const iconeFechado = 'lock-outline';
  static const iconeCategoria = 'tag-outline';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(FaleConoscoViewmodel vm, Result? result) => switch (result) {
    Error(error: final error) => vm.mensagemErro(error),
    _ => kDefaultAppError,
  };

  @override
  State<FaleConoscoView> createState() => _FaleConoscoViewState();
}

class _FaleConoscoViewState extends State<FaleConoscoView> {
  FaleConoscoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.carregarCommand.addListener(_onCarregar);
  }

  @override
  void didUpdateWidget(covariant FaleConoscoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.carregarCommand.removeListener(_onCarregar);
    _vm.carregarCommand.addListener(_onCarregar);
  }

  @override
  void dispose() {
    _vm.carregarCommand.removeListener(_onCarregar);
    super.dispose();
  }

  /// Erro de atualização (com lista já carregada) vira SnackBar.
  void _onCarregar() {
    final command = _vm.carregarCommand;
    if (!mounted || !command.error || _vm.dados == null) return;
    final mensagem = FaleConoscoView.mensagemErro(_vm, command.result);
    command.clearResult();
    _mensagem(AppLocalizations.of(context).translate(mensagem));
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _novaMensagem() {
    FaleConoscoFormDialog.show(
      context,
      viewModel: _vm,
      onEnviado: (envio) {
        if (!mounted) return;
        _mensagem('${AppLocalizations.of(context).translate('chamadoEnviado')}: ${envio.fconProtocolo}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final dados = _vm.dados;

    final Widget body;
    if (dados == null && !command.error) {
      body = const Loading();
    } else if (dados == null) {
      body = _erroCarregamento(strings);
    } else {
      final chamados = _vm.chamados;
      body = Column(
        children: [
          if (_vm.ocupado) const LinearProgressIndicator() else const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: command.execute,
              child: chamados.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: constraints.maxHeight, child: _vazio(strings)),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: chamados.length,
                      itemBuilder: (context, index) => _chamado(chamados[index], strings),
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('faleConosco')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: _vm.ocupado ? null : command.execute,
            icon: FaleConoscoView.icone(FaleConoscoView.iconeAtualizar, Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: ViewBottomActions(
        optionButton2: ViewBottomAction(
          text: strings.translate('novaMensagem'),
          icon: IconsMap.mdiIcons[FaleConoscoView.iconeNova] ?? Icons.edit_outlined,
          isEnabled: dados != null,
          onPressed: _novaMensagem,
        ),
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
            Text(strings.translate(FaleConoscoView.mensagemErro(_vm, command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: FaleConoscoView.icone(FaleConoscoView.iconeAtualizar, Icons.refresh),
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
            FaleConoscoView.icone(FaleConoscoView.iconeTela, Icons.support_agent, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumChamado'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _chamado(FaleConoscoModel chamado, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final respondido = chamado.fconPrimeiraRespostaEm != null;
    final (icone, fallback) = chamado.fechado
        ? (FaleConoscoView.iconeFechado, Icons.lock_outline)
        : respondido
        ? (FaleConoscoView.iconeRespondido, Icons.reply)
        : (FaleConoscoView.iconeAguardando, Icons.schedule);
    final enviado = _vm.data(chamado.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => FaleConoscoDetalheDialog.show(context, viewModel: _vm, chamado: chamado),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: chamado.fechado ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                child: FaleConoscoView.icone(
                  icone,
                  fallback,
                  color: chamado.fechado ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chamado.fconAssunto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
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
                          strings.translate(_vm.situacao(chamado.fconStatus)),
                          fundo: chamado.fechado ? scheme.surfaceContainerHighest : scheme.secondaryContainer,
                          cor: chamado.fechado ? scheme.onSurfaceVariant : scheme.onSecondaryContainer,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaleConoscoView.icone(
                              FaleConoscoView.iconeCategoria,
                              Icons.sell_outlined,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(strings.translate(_vm.categoria(chamado.fconCategoria)), style: secundario),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto, {required Color fundo, required Color cor}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
    child: Text(texto, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor)),
  );
}
