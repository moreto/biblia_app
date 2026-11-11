import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../mensagem_lista_view.dart';
import '../mensagem_lista_viewmodel.dart';

/// Mensagem completa, aberta ao tocar no card da tela "Mensagens": título, remetente ("Sistema" nas de sistema),
/// recebida em, lida em (se lida), texto inteiro (selecionável) e a resposta do usuário (se respondeu).
///
/// Acompanha a versão da lista ([musuId]): ao arquivar/desarquivar aqui ([MensagemListaViewmodel.arquivarCommand])
/// o botão muda; arquivar também fecha. Aberta no `DialogBottomSheet` ([show]), com o título da mensagem no topo.
///
/// Ícones: os de [MensagemListaView] ([MensagemListaView.iconeArquivar], [MensagemListaView.iconeDesarquivar]) e
/// [iconeResposta].
class MensagemDetalheDialog extends StatelessWidget {
  const MensagemDetalheDialog({super.key, required this.viewModel, required this.musuId});

  final MensagemListaViewmodel viewModel;
  final int musuId;

  static const iconeResposta = 'message-reply-text-outline';

  static Future<void> show(BuildContext context, {required MensagemListaViewmodel viewModel, required int musuId}) =>
      DialogSheet.show<void>(
        context,
        titulo: viewModel.mensagem(musuId)?.mensTitulo,
        conteudo: MensagemDetalheDialog(viewModel: viewModel, musuId: musuId),
      );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final mensagem = viewModel.mensagem(musuId);
        if (mensagem == null) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final secundario = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
        final remetente = viewModel.remetente(mensagem) ?? strings.translate('sistema');
        final recebida = viewModel.data(mensagem.recebidaEm);
        final lida = mensagem.musuLida ? viewModel.data(mensagem.musuLidaEm) : null;
        final resposta = viewModel.resposta(mensagem);
        final arquivada = mensagem.musuArquivada;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${strings.translate('de')}: $remetente', style: textTheme.bodyMedium),
            if (recebida != null) Text('${strings.translate('recebidaEm')}: $recebida', style: secundario),
            if (lida != null) Text('${strings.translate('lidaEm')}: $lida', style: secundario),
            const Divider(height: 24),
            SelectableText(mensagem.mensTexto.trim(), style: textTheme.bodyLarge?.copyWith(height: 1.5)),
            if (resposta != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MensagemListaView.icone(iconeResposta, Icons.reply, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.translate('suaResposta'), style: textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(resposta),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            DialogSheet.acoes([
              TextButton.icon(
                onPressed: viewModel.gravando
                    ? null
                    : () {
                        viewModel.arquivarCommand.execute(mensagem);
                        if (!arquivada) Navigator.of(context).pop();
                      },
                icon: arquivada
                    ? MensagemListaView.icone(MensagemListaView.iconeDesarquivar, Icons.unarchive_outlined)
                    : MensagemListaView.icone(MensagemListaView.iconeArquivar, Icons.archive_outlined),
                label: Text(strings.translate(arquivada ? 'desarquivar' : 'arquivar')),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('fechar'))),
            ]),
          ],
        );
      },
    );
  }
}
