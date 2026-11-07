import 'package:app/config/command.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import '../biblia_leitura_view.dart';
import '../biblia_leitura_viewmodel.dart';

/// Indicações do versículo selecionado (`/v1/versiculo-indicacao`): total de indicações, a do usuário com o
/// comentário e as ações de indicar, atualizar o comentário e remover a indicação. Erros aparecem na própria folha.
class VersiculoIndicacaoSheet extends StatefulWidget {
  const VersiculoIndicacaoSheet({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  @override
  State<VersiculoIndicacaoSheet> createState() => _VersiculoIndicacaoSheetState();
}

class _VersiculoIndicacaoSheetState extends State<VersiculoIndicacaoSheet> {
  final _comentario = TextEditingController();

  /// `vindId` cujo comentário já foi copiado para o campo; evita sobrescrever o que o usuário digita.
  int? _comentarioDe;

  BibliaLeituraViewmodel get _vm => widget.viewModel;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _sincronizarComentario() {
    final minha = _vm.indicacoes?.minha;
    if (minha?.vindId != _comentarioDe) {
      _comentarioDe = minha?.vindId;
      _comentario.text = minha?.vindComentario ?? '';
    }
  }

  String? _erro() {
    for (final Command command in [_vm.indicacoesCommand, _vm.indicarCommand, _vm.removerIndicacaoCommand]) {
      if (command.error) return BibliaLeituraView.mensagemErro(command.result);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.indicarCommand, _vm.removerIndicacaoCommand, _vm.indicacoesCommand]),
      builder: (context, _) {
        final versiculo = _vm.versiculoSelecionado;
        if (versiculo == null) return const SizedBox.shrink();

        _sincronizarComentario();
        final indicacoes = _vm.indicacoes;
        final minha = indicacoes?.minha;
        final gravando = _vm.indicarCommand.running || _vm.removerIndicacaoCommand.running;
        final erro = _erro();

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(versiculo.referencia, style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(versiculo.versTexto, style: textTheme.bodyLarge),
              const SizedBox(height: 16),
              if (indicacoes == null && _vm.indicacoesCommand.running)
                const Center(child: CircularProgressIndicator())
              else if (indicacoes != null) ...[
                _total(indicacoes, strings),
                const SizedBox(height: 12),
                TextField(
                  controller: _comentario,
                  enabled: !gravando,
                  maxLength: VersiculoIndicacaoUseCase.comentarioMaximo,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(labelText: strings.translate('comentarioOpcional')),
                ),
                Row(
                  children: [
                    if (minha != null)
                      TextButton.icon(
                        onPressed: gravando ? null : _vm.removerIndicacaoCommand.execute,
                        icon: BibliaLeituraView.icone(BibliaLeituraView.iconeRemover, Icons.delete_outline),
                        label: Text(strings.translate('removerIndicacao')),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: gravando ? null : () => _vm.indicarCommand.execute(_comentario.text),
                      icon: BibliaLeituraView.icone(BibliaLeituraView.iconeIndicar, Icons.thumb_up_outlined),
                      label: Text(strings.translate(minha == null ? 'indicarVersiculo' : 'atualizarIndicacao')),
                    ),
                  ],
                ),
              ],
              if (erro != null) ...[
                const SizedBox(height: 8),
                Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _total(IndicacoesVersiculo indicacoes, AppLocalizations strings) {
    final minha = indicacoes.minha != null;
    return Row(
      children: [
        BibliaLeituraView.icone(
          minha ? BibliaLeituraView.iconeIndicado : BibliaLeituraView.iconeIndicar,
          minha ? Icons.thumb_up : Icons.thumb_up_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${indicacoes.total} ${strings.translate('indicacoes')}'
            '${minha ? ' · ${strings.translate('voceIndicou')}' : ''}',
          ),
        ),
      ],
    );
  }
}
