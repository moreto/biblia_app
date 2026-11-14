import 'dart:async';

import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/dicionario/dicionario_busca_model.dart';
import '../../../../data/model/dicionario/dicionario_verbete_model.dart';
import '../use_case/dicionario_usecase.dart';
import 'dicionario_viewmodel.dart';

/// Tela "Dicionário" (`Routes.dicionario`, tela própria, não é aba): busca de palavras com o resultado na mesma
/// página.
///
/// - Campo de busca no topo: enquanto digita (a partir de 2 caracteres e [esperaBusca] depois da última tecla),
///   lista as palavras que começam pelo texto ou são semelhantes (`/v1/dicionario/busca`), com a classe e o começo
///   da definição. Tocar numa palavra ou confirmar no teclado consulta os verbetes (`/v1/dicionario/palavra`).
/// - Verbete: palavra com o homônimo sobrescrito, pronúncia, etimologia e as acepções numeradas (classe, rótulos de
///   uso, definição com itálico e remissões "Veja também", que consultam o termo quando ele existe).
/// - Palavra não encontrada: aviso e as palavras semelhantes.
/// - Erros aparecem no lugar do resultado; o da consulta tem "Tentar novamente".
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeDicionario], [iconeBuscar], [iconeLimpar], [iconeNaoEncontrada],
/// [iconeRemissao], [iconeAbrir] e [iconeErro].
class DicionarioView extends StatefulWidget {
  const DicionarioView({super.key, required this.viewModel});

  final DicionarioViewmodel viewModel;

  /// Espera depois da última tecla para buscar.
  static const esperaBusca = Duration(milliseconds: 400);

  /// Tela (início e `func_icone`/`menu_icone` de /dicionario).
  static const iconeDicionario = 'book-alphabet';
  static const iconeBuscar = 'magnify';
  static const iconeLimpar = 'close';
  static const iconeNaoEncontrada = 'text-search';

  /// Remissão "Veja também".
  static const iconeRemissao = 'link-variant';
  static const iconeAbrir = 'chevron-right';
  static const iconeErro = 'alert-circle-outline';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  @override
  State<DicionarioView> createState() => _DicionarioViewState();
}

class _DicionarioViewState extends State<DicionarioView> {
  DicionarioViewmodel get _vm => widget.viewModel;

  final _busca = TextEditingController();
  final _foco = FocusNode();
  Timer? _esperaBusca;

  @override
  void dispose() {
    _esperaBusca?.cancel();
    _busca.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _onBuscaAlterada(String texto) {
    _esperaBusca?.cancel();
    _esperaBusca = Timer(DicionarioView.esperaBusca, () => _vm.buscar(texto));
    setState(() {});
  }

  /// Consulta [palavra] e a coloca no campo.
  void _consultar(String palavra) {
    _esperaBusca?.cancel();
    if (_busca.text != palavra) {
      _busca.value = TextEditingValue(
        text: palavra,
        selection: TextSelection.collapsed(offset: palavra.length),
      );
    }
    _foco.unfocus();
    _vm.consultarCommand.execute(palavra);
  }

  void _limpar() {
    _esperaBusca?.cancel();
    _busca.clear();
    _vm.limpar();
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('dicionario')),
        elevation: 0,
        actions: const [ThemeModeButton(), OrientationButton()],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _campoBusca(strings),
          if (_vm.ocupado) const LinearProgressIndicator() else const SizedBox(height: 4),
          Expanded(
            child: switch (_vm.exibicao) {
              DicionarioExibicao.inicio => _aviso(
                DicionarioView.iconeDicionario,
                Icons.menu_book_outlined,
                strings.translate('dicionarioInicio'),
              ),
              DicionarioExibicao.sugestoes => _sugestoes(strings),
              DicionarioExibicao.consulta => _consulta(strings),
            },
          ),
        ],
      ),
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  Widget _campoBusca(AppLocalizations strings) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: TextField(
      controller: _busca,
      focusNode: _foco,
      autofocus: true,
      maxLength: _vm.textoMaximo,
      textInputAction: TextInputAction.search,
      onChanged: _onBuscaAlterada,
      onSubmitted: (texto) {
        if (DicionarioUseCase.normalizar(texto).isNotEmpty) _consultar(texto);
      },
      decoration: InputDecoration(
        labelText: strings.translate('buscarPalavra'),
        hintText: strings.translate('buscarPalavraDica'),
        counterText: '',
        prefixIcon: DicionarioView.icone(DicionarioView.iconeBuscar, Icons.search),
        suffixIcon: _busca.text.isEmpty
            ? null
            : IconButton(
                tooltip: strings.translate('limpar'),
                onPressed: _limpar,
                icon: DicionarioView.icone(DicionarioView.iconeLimpar, Icons.close),
              ),
      ),
    ),
  );

  Widget _aviso(String icone, IconData fallback, String texto, {Widget? acao}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DicionarioView.icone(icone, fallback, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
            if (acao != null) ...[const SizedBox(height: 12), acao],
          ],
        ),
      ),
    );
  }

  Widget _sugestoes(AppLocalizations strings) {
    final erro = _vm.erroBusca;
    if (erro != null) {
      return _aviso(DicionarioView.iconeErro, Icons.error_outline, strings.translate(erro));
    }
    final sugestoes = _vm.sugestoes;
    if (sugestoes == null) return const SizedBox.shrink();
    if (sugestoes.isEmpty && !_vm.buscando) {
      return _aviso(DicionarioView.iconeNaoEncontrada, Icons.search_off, strings.translate('nenhumaPalavraEncontrada'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: sugestoes.length,
      itemBuilder: (context, index) => _sugestao(sugestoes[index]),
    );
  }

  Widget _consulta(AppLocalizations strings) {
    final erro = _vm.erroConsulta;
    if (erro != null) {
      return _aviso(
        DicionarioView.iconeErro,
        Icons.error_outline,
        strings.translate(erro),
        acao: FilledButton.icon(
          onPressed: _vm.repetirConsulta,
          icon: DicionarioView.icone(DicionarioView.iconeAtualizar, Icons.refresh),
          label: Text(strings.translate('tentarNovamente')),
        ),
      );
    }
    final consulta = _vm.consulta;
    if (consulta == null) return const SizedBox.shrink();

    if (!consulta.encontrada) {
      final textTheme = Theme.of(context).textTheme;
      return ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                DicionarioView.icone(
                  DicionarioView.iconeNaoEncontrada,
                  Icons.search_off,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${strings.translate('palavraNaoEncontrada')}: "${consulta.termo}"',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          if (consulta.sugestoes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(strings.translate('palavrasSemelhantes'), style: textTheme.titleSmall),
            ),
          for (final s in consulta.sugestoes) _sugestao(s),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final v in consulta.verbetes) _verbete(v, strings),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            strings.translate('dicionarioFonte'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _sugestao(DicionarioBuscaModel item) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resumo = _vm.resumo(item.daceDefinicao);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _consultar(item.dverPalavra),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            (item.dverLetra ?? item.dverPalavra.characters.first).toUpperCase(),
            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _vm.titulo(item.dverPalavra, item.dverHomonimo),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (item.daceClasse != null)
                TextSpan(
                  text: '  ${item.daceClasse}',
                  style: TextStyle(fontStyle: FontStyle.italic, color: scheme.primary),
                ),
            ],
          ),
          style: textTheme.titleMedium,
        ),
        subtitle: resumo == null ? null : Text(resumo, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: DicionarioView.icone(DicionarioView.iconeAbrir, Icons.chevron_right),
      ),
    );
  }

  /// Texto com os trechos em itálico do original.
  TextSpan _texto(String texto, {TextStyle? style}) => TextSpan(
    style: style,
    children: [
      for (final t in _vm.trechos(texto))
        TextSpan(
          text: t.texto,
          style: t.italico ? const TextStyle(fontStyle: FontStyle.italic) : null,
        ),
    ],
  );

  Widget _verbete(DicionarioVerbeteModel verbete, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final acepcoes = _vm.acepcoes(verbete);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  _vm.titulo(verbete.dverPalavra, verbete.dverHomonimo),
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
                ),
                if (verbete.dverPronuncia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('${strings.translate('pronuncia')}: ${verbete.dverPronuncia}', style: secundario),
                  ),
              ],
            ),
            if (verbete.dverEtimologia != null) ...[
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${strings.translate('etimologia')}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _texto(verbete.dverEtimologia!),
                  ],
                ),
                style: secundario,
              ),
            ],
            const Divider(height: 24),
            for (final (index, acepcao) in acepcoes.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              _acepcao(acepcao, numerar: acepcoes.length > 1, strings: strings),
            ],
          ],
        ),
      ),
    );
  }

  Widget _acepcao(DicionarioAcepcaoModel acepcao, {required bool numerar, required AppLocalizations strings}) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final usos = _vm.usos(acepcao);
    final remissoes = _vm.remissoes(acepcao);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (numerar)
          SizedBox(
            width: 28,
            child: Text(
              '${acepcao.daceSeq}.',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (acepcao.daceClasse != null || usos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (acepcao.daceClasse != null)
                        Text(
                          acepcao.daceClasse!,
                          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: scheme.primary),
                        ),
                      for (final uso in usos)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(uso, style: textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer)),
                        ),
                    ],
                  ),
                ),
              Text.rich(_texto(acepcao.daceDefinicao), style: textTheme.bodyLarge),
              if (remissoes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${strings.translate('vejaTambem')}:', style: textTheme.bodySmall),
                      for (final r in remissoes)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: DicionarioView.icone(DicionarioView.iconeRemissao, Icons.link, size: 16),
                          label: Text(r.termo),
                          onPressed: r.navegavel ? () => _consultar(r.termo) : null,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
