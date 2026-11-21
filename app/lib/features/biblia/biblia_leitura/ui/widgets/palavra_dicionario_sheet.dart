import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';

import '../../../../dicionario/ui/widgets/dicionario_verbete_card.dart';
import '../../../../dicionario/use_case/dicionario_usecase.dart';
import '../biblia_leitura_viewmodel.dart';

/// Conteúdo do sheet aberto pelo toque longo numa palavra da leitura: os verbetes da palavra no dicionário.
///
/// Consulta [palavra] ao abrir ([BibliaLeituraViewmodel.consultarPalavraCommand]). Remissões navegáveis e palavras
/// semelhantes (quando a palavra não existe) consultam o termo no próprio sheet. Sem login, mostra o aviso para
/// entrar.
class PalavraDicionarioSheet extends StatefulWidget {
  const PalavraDicionarioSheet({super.key, required this.viewModel, required this.palavra, this.cabecalho});

  final BibliaLeituraViewmodel viewModel;
  final String palavra;

  /// Mostrado acima dos verbetes (o marca-texto da palavra selecionada).
  final Widget? cabecalho;

  @override
  State<PalavraDicionarioSheet> createState() => _PalavraDicionarioSheetState();
}

class _PalavraDicionarioSheetState extends State<PalavraDicionarioSheet> {
  BibliaLeituraViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.consultarPalavraCommand.execute(widget.palavra);
  }

  void _consultar(String termo) => _vm.consultarPalavraCommand.execute(termo);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final command = _vm.consultarPalavraCommand;
    final cabecalho = widget.cabecalho;
    final conteudo = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      child: ListenableBuilder(
        listenable: command,
        builder: (context, _) {
          if (command.running) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return switch (command.result) {
            Ok(value: final consulta) => _consulta(consulta, strings),
            Error(error: final error) => _aviso(strings.translate(DicionarioUseCase.mensagemErro(error))),
            null => const SizedBox.shrink(),
          };
        },
      ),
    );
    if (cabecalho == null) return conteudo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cabecalho,
        Flexible(child: conteudo),
      ],
    );
  }

  Widget _aviso(String texto) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(texto, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
  );

  Widget _consulta(DicionarioConsulta consulta, AppLocalizations strings) {
    if (consulta.encontrada) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final verbete in consulta.verbetes)
              DicionarioVerbeteCard(
                verbete: verbete,
                onRemissao: _consultar,
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
          ],
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.translate('palavraNaoEncontrada')}: "${consulta.termo}"', style: textTheme.titleMedium),
          if (consulta.sugestoes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(strings.translate('palavrasSemelhantes'), style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in consulta.sugestoes)
                  ActionChip(
                    label: Text(DicionarioUseCase.titulo(s.dverPalavra, s.dverHomonimo)),
                    onPressed: () => _consultar(s.dverPalavra),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
