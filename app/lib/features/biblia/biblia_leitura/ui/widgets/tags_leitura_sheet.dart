import 'package:app/config/anotacao_leitura.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../use_case/biblia_leitura_usecase.dart';
import '../biblia_leitura_viewmodel.dart';
import 'tag_cor.dart';

/// Conteúdo do sheet "Gerenciar tags": criar, renomear, trocar a cor (tocando na bolinha) e apagar as tags das
/// anotações da leitura.
///
/// Aberto pelas Opções de leitura e pela anotação de um trecho. Apagar uma tag a tira das anotações.
class TagsLeituraSheet extends StatefulWidget {
  const TagsLeituraSheet({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  @override
  State<TagsLeituraSheet> createState() => _TagsLeituraSheetState();
}

class _TagsLeituraSheetState extends State<TagsLeituraSheet> {
  BibliaLeituraViewmodel get _vm => widget.viewModel;

  final _nova = TextEditingController();
  String? _erroNova;

  /// Cor escolhida para a próxima tag; nula segue a sugerida ([BibliaLeituraViewmodel.corSugerida]).
  CorTag? _corNova;

  /// Tag sendo renomeada e o campo com o nome dela.
  String? _editando;
  final _nome = TextEditingController();
  String? _erroNome;

  /// Tag com a paleta de cores aberta.
  String? _escolhendoCor;

  @override
  void initState() {
    super.initState();
    _vm.carregarTags();
  }

  @override
  void dispose() {
    _nova.dispose();
    _nome.dispose();
    super.dispose();
  }

  void _criar() {
    final erro = _vm.validarTag(_nova.text);
    setState(() => _erroNova = erro);
    if (erro != null) return;
    _vm.criarTag(_nova.text, cor: _corNova);
    _nova.clear();
    _corNova = null;
  }

  void _editar(TagLeitura tag) => setState(() {
    _editando = tag.id;
    _nome.text = tag.nome;
    _erroNome = null;
  });

  void _renomear(String id) {
    final erro = _vm.validarTag(_nome.text, exceto: id);
    setState(() => _erroNome = erro);
    if (erro != null) return;
    _vm.renomearTag(id, _nome.text);
    setState(() => _editando = null);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final tags = _vm.tags;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('novaTag'),
              controller: _nova,
              maxLength: BibliaLeituraUseCase.tamanhoMaximoTag,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _criar(),
              decoration: InputDecoration(
                labelText: strings.translate('novaTag'),
                errorText: _erroNova == null ? null : strings.translate(_erroNova!),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: strings.translate('criarTag'),
                  onPressed: _criar,
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
            TagCor.seletor(
              context,
              atual: _corNova ?? _vm.corSugerida,
              onEscolher: (cor) => setState(() => _corNova = cor),
            ),
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  strings.translate('nenhumaTag'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
                child: ListView(shrinkWrap: true, children: [for (final tag in tags) _tag(tag, strings)]),
              ),
          ],
        );
      },
    );
  }

  Widget _tag(TagLeitura tag, AppLocalizations strings) {
    if (_editando == tag.id) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextField(
          key: ValueKey('renomearTag_${tag.id}'),
          controller: _nome,
          autofocus: true,
          maxLength: BibliaLeituraUseCase.tamanhoMaximoTag,
          onSubmitted: (_) => _renomear(tag.id),
          decoration: InputDecoration(
            errorText: _erroNome == null ? null : strings.translate(_erroNome!),
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: strings.translate('cancelar'),
                  onPressed: () => setState(() => _editando = null),
                  icon: const Icon(Icons.close),
                ),
                IconButton(
                  tooltip: strings.translate('salvar'),
                  onPressed: () => _renomear(tag.id),
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        tooltip: strings.translate('corTag'),
        onPressed: () => setState(() => _escolhendoCor = _escolhendoCor == tag.id ? null : tag.id),
        icon: TagCor.bolinha(tag.cor, tamanho: 22),
      ),
      title: Text(tag.nome),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: strings.translate('renomearTag'),
            onPressed: () => _editar(tag),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: strings.translate('excluirTag'),
            onPressed: () => _vm.excluirTag(tag.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
    if (_escolhendoCor != tag.id) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        TagCor.seletor(
          context,
          atual: tag.cor,
          onEscolher: (cor) {
            _vm.mudarCorTag(tag.id, cor);
            setState(() => _escolhendoCor = null);
          },
        ),
      ],
    );
  }
}
