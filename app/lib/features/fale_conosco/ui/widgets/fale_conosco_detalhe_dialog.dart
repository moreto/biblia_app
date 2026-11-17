import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/fale_conosco/fale_conosco_model.dart';
import '../fale_conosco_view.dart';
import '../fale_conosco_viewmodel.dart';

/// Chamado do Fale Conosco aberto ao tocar no card ([show], no `DialogBottomSheet`, com o assunto no topo):
/// protocolo, categoria, situação, data de envio, a mensagem original e a conversa (`/v1/fale-conosco/meus/:fconId`):
/// respostas do atendimento à esquerda e as do usuário à direita.
///
/// - Chamado aberto: campo "Responder" com "Enviar" ([FaleConoscoViewmodel.responderCommand]); a conversa é
///   atualizada ao gravar. Erro aparece abaixo do campo.
/// - Chamado fechado: aviso `chamadoFechadoAviso` no lugar do campo.
/// - Erro ao carregar: mensagem e "Tentar novamente".
///
/// Ícones: [FaleConoscoView.iconeTela] (atendimento), [iconeUsuario], [FaleConoscoView.iconeFechado] e
/// [iconeEnviar].
class FaleConoscoDetalheDialog extends StatefulWidget {
  const FaleConoscoDetalheDialog({super.key, required this.viewModel, required this.chamado});

  final FaleConoscoViewmodel viewModel;

  /// Chamado da lista (para o cabeçalho enquanto o detalhe carrega).
  final FaleConoscoModel chamado;

  static const iconeUsuario = 'account-outline';
  static const iconeEnviar = 'send';

  static Future<void> show(
    BuildContext context, {
    required FaleConoscoViewmodel viewModel,
    required FaleConoscoModel chamado,
  }) {
    viewModel.fecharDetalhe();
    viewModel.detalheCommand.execute(chamado.fconId);
    return DialogSheet.show<void>(
      context,
      titulo: chamado.fconAssunto,
      conteudo: FaleConoscoDetalheDialog(viewModel: viewModel, chamado: chamado),
    );
  }

  @override
  State<FaleConoscoDetalheDialog> createState() => _FaleConoscoDetalheDialogState();
}

class _FaleConoscoDetalheDialogState extends State<FaleConoscoDetalheDialog> {
  final _resposta = TextEditingController();
  String? _erro;

  FaleConoscoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.responderCommand.addListener(_onResponder);
  }

  @override
  void dispose() {
    _vm.responderCommand.removeListener(_onResponder);
    _resposta.dispose();
    super.dispose();
  }

  void _onResponder() {
    final command = _vm.responderCommand;
    if (!mounted || command.running) return;
    if (command.completed) {
      command.clearResult();
      _resposta.clear();
      setState(() => _erro = null);
    } else if (command.error) {
      final mensagem = FaleConoscoView.mensagemErro(_vm, command.result);
      command.clearResult();
      setState(() => _erro = mensagem);
    }
  }

  void _responder() {
    FocusScope.of(context).unfocus();
    _vm.responderCommand.execute(_resposta.text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final strings = AppLocalizations.of(context);
        final detalhe = _vm.detalhe;
        final command = _vm.detalheCommand;
        final chamado = detalhe ?? widget.chamado;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cabecalho(chamado, strings),
            const Divider(height: 24),
            if (detalhe == null && command.error)
              _erroCarregamento(strings)
            else if (detalhe == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _balao(texto: detalhe.fconMensagem, quando: detalhe.createdAt, doUsuario: true, strings: strings),
              for (final i in detalhe.interacoes)
                _balao(texto: i.fcinTexto, quando: i.createdAt, doUsuario: i.fcinSolicitante, strings: strings),
              if (detalhe.interacoes.where((i) => !i.fcinSolicitante).isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    strings.translate('aguardandoResposta'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              detalhe.fechado ? _fechado(strings) : _campoResposta(strings),
            ],
            DialogSheet.acoes([
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('fechar'))),
            ]),
          ],
        );
      },
    );
  }

  Widget _cabecalho(FaleConoscoModel chamado, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final secundario = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final enviado = _vm.data(chamado.createdAt);
    final fechado = _vm.data(chamado.fconFechadoEm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${strings.translate('protocolo')}: ${chamado.fconProtocolo}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '${strings.translate('categoria')}: ${strings.translate(_vm.categoria(chamado.fconCategoria))} · '
          '${strings.translate('situacao')}: ${strings.translate(_vm.situacao(chamado.fconStatus))}',
          style: secundario,
        ),
        if (enviado != null) Text('${strings.translate('enviadoEm')}: $enviado', style: secundario),
        if (fechado != null) Text('${strings.translate('fechadoEm')}: $fechado', style: secundario),
      ],
    );
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.detalheCommand;
    return Column(
      children: [
        Text(strings.translate(FaleConoscoView.mensagemErro(_vm, command.result)), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: command.running ? null : () => command.execute(widget.chamado.fconId),
          icon: FaleConoscoView.icone(FaleConoscoView.iconeAtualizar, Icons.refresh),
          label: Text(strings.translate('tentarNovamente')),
        ),
      ],
    );
  }

  /// Mensagem da conversa: do usuário à direita, do atendimento à esquerda.
  Widget _balao({
    required String texto,
    required DateTime? quando,
    required bool doUsuario,
    required AppLocalizations strings,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final autor = strings.translate(doUsuario ? 'voce' : 'atendimento');
    final data = _vm.data(quando);
    final cor = doUsuario ? scheme.onPrimaryContainer : scheme.onSurface;
    return Align(
      alignment: doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: EdgeInsets.only(top: 8, left: doUsuario ? 32 : 0, right: doUsuario ? 0 : 32),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: doUsuario ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                doUsuario
                    ? FaleConoscoView.icone(
                        FaleConoscoDetalheDialog.iconeUsuario,
                        Icons.person_outline,
                        size: 16,
                        color: cor,
                      )
                    : FaleConoscoView.icone(FaleConoscoView.iconeTela, Icons.support_agent, size: 16, color: cor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    [autor, ?data].join(' · '),
                    style: textTheme.labelSmall?.copyWith(color: cor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(texto.trim(), style: textTheme.bodyMedium?.copyWith(color: cor, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _fechado(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        FaleConoscoView.icone(FaleConoscoView.iconeFechado, Icons.lock_outline, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(strings.translate('chamadoFechadoAviso'))),
      ],
    );
  }

  Widget _campoResposta(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final enviando = _vm.responderCommand.running;
    final erro = _erro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _resposta,
          enabled: !enviando,
          maxLength: _vm.textoMaximo,
          minLines: 2,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: strings.translate('responder'), alignLabelWithHint: true),
        ),
        if (erro != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(strings.translate(erro), style: TextStyle(color: scheme.error)),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: enviando ? null : _responder,
            icon: enviando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : FaleConoscoView.icone(FaleConoscoDetalheDialog.iconeEnviar, Icons.send),
            label: Text(strings.translate('enviar')),
          ),
        ),
      ],
    );
  }
}
