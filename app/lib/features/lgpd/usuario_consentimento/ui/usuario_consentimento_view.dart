import 'package:app/config/command.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../data/model/usuario/usuario_consentimento_model.dart';
import '../use_case/usuario_consentimento_usecase.dart';
import 'usuario_consentimento_viewmodel.dart';

/// Tela "Privacidade e consentimentos" (`Routes.usuarioConsentimento`, tela própria, não é aba): o usuário lê e
/// aceita os termos de cada finalidade (LGPD art. 8º e 11) e pode revogar o aceite (`/v1/usuario-consentimento`).
///
/// - Topo: explicação da tela e, se todos os termos estiverem aceitos, o aviso `consentimentosEmDia`.
/// - Um card por termo ([ConsentimentoFinalidade]): ícone, título, situação ("Aceito"/"Pendente"), descrição, versão
///   do termo e data do aceite. Pendente: botão "Aceitar". Aceito: "Revogar", que pede confirmação (com aviso extra
///   para dados religiosos: sem eles a API recusa gravar leituras, reações, indicações e comunidades).
/// - "Histórico": aceites e revogações, do mais recente ao mais antigo.
/// - Parte inferior: "Aceitar todos" ao lado de "Voltar", enquanto houver termo pendente.
/// - Primeiro carregamento: progresso; se falhar, "Tentar novamente". Depois disso a lista é mantida; erros de
///   atualização e de gravação viram SnackBar, e gravações concluídas também (`consentimentoRegistrado`,
///   `consentimentosRegistrados`, `consentimentoRevogado`).
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeTela], [iconeAceito], [iconePendente], [iconeAceitar],
/// [iconeAceitarTodos], [iconeRevogar], [iconeHistorico], [iconeRevogado], [iconeAtualizar] e o
/// [ConsentimentoFinalidade.icone] de cada termo.
class UsuarioConsentimentoView extends StatefulWidget {
  const UsuarioConsentimentoView({super.key, required this.viewModel});

  final UsuarioConsentimentoViewmodel viewModel;

  /// Tela (topo; também `func_icone` de /usuario-consentimento).
  static const iconeTela = 'shield-account-outline';
  static const iconeAceito = 'check-circle';
  static const iconePendente = 'alert-circle-outline';
  static const iconeAceitar = 'check';
  static const iconeAceitarTodos = 'check-all';
  static const iconeRevogar = 'close-circle-outline';
  static const iconeHistorico = 'history';

  /// Registro revogado no histórico; o vigente usa [iconeAceito].
  static const iconeRevogado = 'cancel';
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
  State<UsuarioConsentimentoView> createState() => _UsuarioConsentimentoViewState();
}

class _UsuarioConsentimentoViewState extends State<UsuarioConsentimentoView> {
  UsuarioConsentimentoViewmodel get _vm => widget.viewModel;

  /// Comandos de gravação e a mensagem de sucesso de cada um.
  Map<Command, String> _gravacoes(UsuarioConsentimentoViewmodel vm) => {
    vm.aceitarCommand: UsuarioConsentimentoUseCase.kAceito,
    vm.aceitarTodosCommand: UsuarioConsentimentoUseCase.kAceitosTodos,
    vm.revogarCommand: UsuarioConsentimentoUseCase.kRevogado,
  };

  List<Command> _comandos(UsuarioConsentimentoViewmodel vm) => [vm.carregarCommand, ..._gravacoes(vm).keys];

  @override
  void initState() {
    super.initState();
    for (final c in _comandos(_vm)) {
      c.addListener(_onResult);
    }
  }

  @override
  void didUpdateWidget(covariant UsuarioConsentimentoView oldWidget) {
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

  /// Erros de atualização (com lista já carregada) e de gravação, e gravações concluídas, viram SnackBar.
  void _onResult() {
    if (!mounted) return;
    final carregar = _vm.carregarCommand;
    if (carregar.error && _vm.lista != null) {
      final mensagem = UsuarioConsentimentoView.mensagemErro(carregar.result);
      carregar.clearResult();
      _mensagem(mensagem);
    }
    for (final MapEntry(key: command, value: sucesso) in _gravacoes(_vm).entries) {
      if (command.error) {
        final mensagem = UsuarioConsentimentoView.mensagemErro(command.result);
        command.clearResult();
        _mensagem(mensagem);
      } else if (command.completed) {
        command.clearResult();
        _mensagem(sucesso);
      }
    }
  }

  void _mensagem(String chave) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(chave))));
  }

  /// Confirma a revogação do aceite do [termo].
  void _revogar(UsuarioConsentimentoTermoModel termo) {
    final strings = AppLocalizations.of(context);
    final aviso = _vm.avisoRevogacao(termo.finalidade);
    DialogBottomSheetWarning(
      dialogWarning: DialogWarning(
        title: strings.translate('revogarConsentimento'),
        description: [
          strings.translate(_vm.titulo(termo.finalidade)),
          strings.translate('revogarConsentimentoDescricao'),
          if (aviso != null) strings.translate(aviso),
        ].join('\n\n'),
        titleButtonPrimary: strings.translate('revogar'),
        titleButtonSecondary: strings.translate('cancelar'),
        typeButtonsDialog: DialogBottomSheetTypeButtons.horizontalButtons,
        statusDialog: DialogBottomSheetStatus.statusCritical,
        onPressedPrimary: () {
          Navigator.of(context).pop();
          _vm.revogarCommand.execute(termo);
        },
        onPressedSecondary: () => Navigator.of(context).pop(),
      ),
    ).showModal(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final lista = _vm.lista;

    final Widget body;
    if (lista == null && !command.error) {
      body = const Loading();
    } else if (lista == null) {
      body = _erroCarregamento(strings);
    } else {
      body = Column(
        children: [
          if (_vm.ocupado) const LinearProgressIndicator() else const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: command.execute,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  _introducao(strings),
                  if (_vm.todosAceitos) _emDia(strings),
                  for (final termo in _vm.termos) _termo(termo, strings),
                  _historico(strings),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final pendentes = _vm.pendentes;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('privacidadeConsentimentos')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: _vm.ocupado ? null : command.execute,
            icon: UsuarioConsentimentoView.icone(UsuarioConsentimentoView.iconeAtualizar, Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: ViewBottomActions(
        optionButton2: ViewBottomAction(
          text: strings.translate('aceitarTodos'),
          icon: IconsMap.mdiIcons[UsuarioConsentimentoView.iconeAceitarTodos] ?? Icons.done_all,
          isVisible: lista != null && pendentes.isNotEmpty,
          isEnabled: !_vm.ocupado,
          onPressed: _vm.aceitarTodosCommand.execute,
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
            Text(strings.translate(UsuarioConsentimentoView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: UsuarioConsentimentoView.icone(UsuarioConsentimentoView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introducao(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UsuarioConsentimentoView.icone(
            UsuarioConsentimentoView.iconeTela,
            Icons.privacy_tip_outlined,
            size: 32,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(strings.translate('consentimentoIntro'), style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _emDia(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: scheme.primaryContainer,
      child: ListTile(
        leading: UsuarioConsentimentoView.icone(
          UsuarioConsentimentoView.iconeAceito,
          Icons.check_circle,
          color: scheme.onPrimaryContainer,
        ),
        title: Text(strings.translate('consentimentosEmDia'), style: TextStyle(color: scheme.onPrimaryContainer)),
      ),
    );
  }

  Widget _termo(UsuarioConsentimentoTermoModel termo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final descricao = _vm.descricao(termo.finalidade);
    final aceitoEm = _vm.data(_vm.aceite(termo)?.createdAt);
    final habilitado = !_vm.ocupado;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: termo.aceito ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                  child: UsuarioConsentimentoView.icone(
                    _vm.icone(termo.finalidade),
                    Icons.privacy_tip_outlined,
                    color: termo.aceito ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.translate(_vm.titulo(termo.finalidade)),
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _situacao(termo.aceito, strings),
                    ],
                  ),
                ),
              ],
            ),
            if (descricao != null) ...[
              const SizedBox(height: 12),
              Text(strings.translate(descricao), style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text(
              [
                '${strings.translate('versaoTermo')}: ${termo.versao}',
                if (aceitoEm != null) '${strings.translate('aceitoEm')}: $aceitoEm',
              ].join(' · '),
              style: secundario,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: termo.aceito
                  ? OutlinedButton.icon(
                      onPressed: habilitado ? () => _revogar(termo) : null,
                      icon: UsuarioConsentimentoView.icone(
                        UsuarioConsentimentoView.iconeRevogar,
                        Icons.cancel_outlined,
                      ),
                      label: Text(strings.translate('revogar')),
                    )
                  : FilledButton.icon(
                      onPressed: habilitado ? () => _vm.aceitarCommand.execute(termo) : null,
                      icon: UsuarioConsentimentoView.icone(UsuarioConsentimentoView.iconeAceitar, Icons.check),
                      label: Text(strings.translate('aceitar')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Etiqueta "Aceito" / "Pendente".
  Widget _situacao(bool aceito, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final fundo = aceito ? scheme.primaryContainer : scheme.errorContainer;
    final cor = aceito ? scheme.onPrimaryContainer : scheme.onErrorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          aceito
              ? UsuarioConsentimentoView.icone(
                  UsuarioConsentimentoView.iconeAceito,
                  Icons.check_circle,
                  size: 16,
                  color: cor,
                )
              : UsuarioConsentimentoView.icone(
                  UsuarioConsentimentoView.iconePendente,
                  Icons.error_outline,
                  size: 16,
                  color: cor,
                ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              strings.translate(aceito ? 'consentimentoAceito' : 'consentimentoPendente'),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historico(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final historico = _vm.historico;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: UsuarioConsentimentoView.icone(UsuarioConsentimentoView.iconeHistorico, Icons.history),
        title: Text(strings.translate('historicoConsentimentos')),
        subtitle: Text('${historico.length}'),
        children: [
          if (historico.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(strings.translate('nenhumConsentimentoRegistrado'), textAlign: TextAlign.center),
            ),
          for (final registro in historico)
            ListTile(
              leading: registro.revogado
                  ? UsuarioConsentimentoView.icone(
                      UsuarioConsentimentoView.iconeRevogado,
                      Icons.block,
                      color: scheme.onSurfaceVariant,
                    )
                  : UsuarioConsentimentoView.icone(
                      UsuarioConsentimentoView.iconeAceito,
                      Icons.check_circle,
                      color: scheme.primary,
                    ),
              title: Text(
                '${strings.translate(_vm.titulo(registro.ucnsFinalidade))} · '
                '${strings.translate('versaoTermo')} ${registro.ucnsVersao}',
              ),
              subtitle: Text(
                [
                  if (_vm.data(registro.createdAt) case final aceito?) '${strings.translate('aceitoEm')}: $aceito',
                  if (_vm.data(registro.ucnsRevogadoEm) case final revogado?)
                    '${strings.translate('revogadoEm')}: $revogado',
                ].join('\n'),
              ),
            ),
        ],
      ),
    );
  }
}
