import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_local_model.dart';
import '../../comunidade/ui/comunidade_view.dart';
import 'comunidade_lista_viewmodel.dart';

/// Tela "Encontrar comunidades" (`Routes.comunidadeLista`): todas as comunidades, de qualquer usuário, filtradas por
/// estado e cidade (`/v1/comunidade?estaId=&muniId=`). Tela própria, não é aba de "Comunidades".
///
/// - Topo: estado (obrigatório) e cidade ("Todas as cidades" ou uma do estado); trocar o filtro busca de novo.
/// - Cada comunidade mostra o ícone do tipo (`ctip_icone`; sem ele, o padrão), o nome, tipo · denominação, o
///   endereço e bairro · cidade - UF.
/// - Sem estado: `selecioneEstado`; sem resultado: `nenhumaComunidadeNoLocal`. Erro na primeira busca mostra
///   "Tentar novamente"; depois disso a lista é mantida e o erro vira SnackBar. Falha nos estados mostra
///   "Tentar novamente" no lugar do filtro.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeEncontrar], [iconeEndereco] e o ícone de cada tipo, além de
/// `ComunidadeView.iconeAtualizar`.
class ComunidadeListaView extends StatefulWidget {
  const ComunidadeListaView({super.key, required this.viewModel});

  final ComunidadeListaViewmodel viewModel;

  /// Ícone da tela (menu) e da mensagem inicial.
  static const iconeEncontrar = 'map-search-outline';

  /// Ícone das linhas de endereço.
  static const iconeEndereco = 'map-marker-outline';

  @override
  State<ComunidadeListaView> createState() => _ComunidadeListaViewState();
}

class _ComunidadeListaViewState extends State<ComunidadeListaView> {
  ComunidadeListaViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.buscarCommand.addListener(_onBusca);
  }

  @override
  void didUpdateWidget(covariant ComunidadeListaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.buscarCommand.removeListener(_onBusca);
    _vm.buscarCommand.addListener(_onBusca);
  }

  @override
  void dispose() {
    _vm.buscarCommand.removeListener(_onBusca);
    super.dispose();
  }

  /// Erro de uma busca com lista já mostrada vira SnackBar (a lista é mantida).
  void _onBusca() {
    final command = _vm.buscarCommand;
    if (!mounted || !command.error || _vm.comunidades == null) return;
    final mensagem = ComunidadeView.mensagemErro(command.result);
    command.clearResult();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  static Widget _icone(String chave, IconData fallback, {Color? color, double? size}) =>
      ComunidadeView.icone(chave, fallback, color: color, size: size);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final buscar = _vm.buscarCommand;
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.translate('encontrarComunidades')),
            elevation: 0,
            actions: [
              const ThemeModeButton(),
              const OrientationButton(),
              IconButton(
                tooltip: strings.translate('atualizar'),
                onPressed: _vm.estaId == null || buscar.running ? null : buscar.execute,
                icon: _icone(ComunidadeView.iconeAtualizar, Icons.refresh),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              if (_vm.ocupado) const LinearProgressIndicator(),
              _filtro(context, strings),
              Expanded(child: _resultado(context, strings)),
            ],
          ),
          bottomNavigationBar: ViewBottomActions(
            backLabel: strings.translate('voltar'),
            hideActionsTooltip: strings.translate('ocultarAcoes'),
            showActionsTooltip: strings.translate('exibirAcoes'),
          ),
        );
      },
    );
  }

  /// Estado e cidade, lado a lado (empilhados em telas estreitas).
  Widget _filtro(BuildContext context, AppLocalizations strings) {
    final estados = _vm.estados;
    if (estados == null && _vm.estadosCommand.error) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Expanded(child: Text(strings.translate(ComunidadeView.mensagemErro(_vm.estadosCommand.result)))),
            TextButton(onPressed: _vm.estadosCommand.execute, child: Text(strings.translate('tentarNovamente'))),
          ],
        ),
      );
    }

    final estado = DropdownButtonFormField<int>(
      key: ValueKey('estado-${estados?.length}'),
      initialValue: _vm.estaId,
      isExpanded: true,
      decoration: InputDecoration(labelText: strings.translate('estado')),
      items: [
        for (final e in estados ?? const [])
          DropdownMenuItem(
            value: e.estaId,
            child: Text('${e.estaSigla} · ${e.estaNome}', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: estados == null ? null : (estaId) => estaId == null ? null : _vm.selecionarEstado(estaId),
    );
    final municipios = _vm.municipios;
    final cidade = DropdownButtonFormField<int?>(
      key: ValueKey('cidade-${_vm.estaId}-${municipios?.length}'),
      initialValue: _vm.muniId,
      isExpanded: true,
      decoration: InputDecoration(labelText: strings.translate('municipio')),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(strings.translate('todasAsCidades'))),
        for (final m in municipios ?? const [])
          DropdownMenuItem<int?>(
            value: m.muniId,
            child: Text(m.muniNome, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: municipios == null || municipios.isEmpty ? null : _vm.selecionarCidade,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 520
            ? Column(children: [estado, const SizedBox(height: 12), cidade])
            : Row(
                children: [
                  Expanded(child: estado),
                  const SizedBox(width: 12),
                  Expanded(child: cidade),
                ],
              ),
      ),
    );
  }

  Widget _resultado(BuildContext context, AppLocalizations strings) {
    final command = _vm.buscarCommand;
    final comunidades = _vm.comunidades;

    if (_vm.estaId == null) return _mensagem(context, strings.translate('selecioneEstado'));
    if (comunidades == null && command.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.translate(ComunidadeView.mensagemErro(command.result)), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: command.running ? null : command.execute,
                icon: _icone(ComunidadeView.iconeAtualizar, Icons.refresh),
                label: Text(strings.translate('tentarNovamente')),
              ),
            ],
          ),
        ),
      );
    }
    if (comunidades == null) return const Loading();

    return RefreshIndicator(
      onRefresh: command.execute,
      child: comunidades.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: _mensagem(context, strings.translate('nenhumaComunidadeNoLocal')),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: comunidades.length,
              itemBuilder: (context, index) => _comunidade(context, comunidades[index]),
            ),
    );
  }

  Widget _mensagem(BuildContext context, String texto) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icone(ComunidadeListaView.iconeEncontrar, Icons.travel_explore, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _comunidade(BuildContext context, ComunidadeLocalModel comunidade) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final secundario = textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final descricao = _vm.descricao(comunidade);
    final endereco = _vm.linhaEndereco(comunidade);
    final local = _vm.linhaLocal(comunidade);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: ComunidadeView.iconeDaComunidade(comunidade.ctipIcone, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comunidade.comuNome, style: textTheme.titleMedium),
                  if (descricao != null) ...[const SizedBox(height: 2), Text(descricao, style: secundario)],
                  if (endereco != null || local != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _icone(
                          ComunidadeListaView.iconeEndereco,
                          Icons.place_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (endereco != null) Text(endereco, style: textTheme.bodyMedium),
                              if (local != null) Text(local, style: secundario),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
