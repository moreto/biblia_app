import 'package:app/config/anotacao_leitura.dart';
import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../use_case/biblia_leitura_usecase.dart';
import '../biblia_leitura_viewmodel.dart';
import 'tag_cor.dart';
import 'tags_leitura_sheet.dart';

/// Tags do trecho selecionado, no sheet do trecho: chips para marcar e desmarcar (grava na hora), "Nova tag" (cria
/// já marcada, com a cor sugerida, trocável na paleta) e a engrenagem do "Gerenciar tags".
///
/// Com tag, o trecho fica pintado na cor da primeira tag marcada.
class TagsTrecho extends StatefulWidget {
  const TagsTrecho({super.key, required this.viewModel, required this.inicio, required this.fim});

  final BibliaLeituraViewmodel viewModel;
  final ({int indice, int offset}) inicio;
  final ({int indice, int offset}) fim;

  @override
  State<TagsTrecho> createState() => _TagsTrechoState();
}

class _TagsTrechoState extends State<TagsTrecho> {
  BibliaLeituraViewmodel get _vm => widget.viewModel;

  bool _criando = false;
  final _nome = TextEditingController();
  String? _erro;

  /// Cor da tag sendo criada: começa na sugerida ([BibliaLeituraViewmodel.corSugerida]).
  CorTag _cor = CorTag.azul;

  @override
  void initState() {
    super.initState();
    _vm.carregarTags();
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _criar() {
    final erro = _vm.validarTag(_nome.text);
    setState(() => _erro = erro);
    if (erro != null) return;
    final tag = _vm.criarTag(_nome.text, cor: _cor);
    _vm.alternarTagTrecho(widget.inicio, widget.fim, tag.id);
    setState(() {
      _nome.clear();
      _criando = false;
    });
  }

  Future<void> _gerenciar() => DialogSheet.show<void>(
    context,
    titulo: AppLocalizations.of(context).translate('gerenciarTags'),
    conteudo: TagsLeituraSheet(viewModel: _vm),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final marcadas = _vm.tagsDoTrecho(widget.inicio, widget.fim);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(strings.translate('tags'), style: Theme.of(context).textTheme.labelLarge)),
                  IconButton(
                    tooltip: strings.translate('gerenciarTags'),
                    onPressed: _gerenciar,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in _vm.tags)
                    FilterChip(
                      avatar: TagCor.bolinha(tag.cor),
                      showCheckmark: false,
                      label: Text(tag.nome),
                      backgroundColor: TagCor.fundo(tag.cor),
                      selectedColor: TagCor.fundo(tag.cor, selecionada: true),
                      side: marcadas.contains(tag.id)
                          ? BorderSide(color: tag.cor.cor, width: 2)
                          : TagCor.borda(tag.cor),
                      selected: marcadas.contains(tag.id),
                      onSelected: (_) => _vm.alternarTagTrecho(widget.inicio, widget.fim, tag.id),
                    ),
                  if (!_criando)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: Text(strings.translate('novaTag')),
                      onPressed: () => setState(() {
                        _criando = true;
                        _cor = _vm.corSugerida;
                      }),
                    ),
                ],
              ),
              if (_criando) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    key: const ValueKey('novaTagTrecho'),
                    controller: _nome,
                    autofocus: true,
                    maxLength: BibliaLeituraUseCase.tamanhoMaximoTag,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _criar(),
                    decoration: InputDecoration(
                      labelText: strings.translate('novaTag'),
                      errorText: _erro == null ? null : strings.translate(_erro!),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: strings.translate('criarTag'),
                        onPressed: _criar,
                        icon: const Icon(Icons.check),
                      ),
                    ),
                  ),
                ),
                TagCor.seletor(context, atual: _cor, onEscolher: (cor) => setState(() => _cor = cor)),
              ],
            ],
          ),
        );
      },
    );
  }
}
