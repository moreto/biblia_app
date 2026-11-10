import 'dart:async';

import 'package:app/config/command.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../versiculo_indicacao/use_case/versiculo_indicacao_usecase.dart';
import '../biblia_leitura_view.dart';
import '../biblia_leitura_viewmodel.dart';

/// Indicações do versículo selecionado (`/v1/versiculo-indicacao`): total de indicações, a do usuário com o
/// comentário e as ações de indicar, atualizar o comentário e remover a indicação. Depois de indicar, a seção
/// "Indicar para" lista os usuários que recebem a indicação (`/v1/versiculo-indicacao-usuario`) e busca outros
/// (`/v1/usuario/busca`) para adicionar. Erros aparecem na própria folha.
class VersiculoIndicacaoSheet extends StatefulWidget {
  const VersiculoIndicacaoSheet({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  /// Fração da altura da tela ocupada ao abrir; o usuário pode arrastar até quase a tela toda.
  static const alturaInicial = 0.75;

  /// Espera depois da última tecla antes de buscar usuários.
  static const esperaBusca = Duration(milliseconds: 400);

  /// Ícones (em [IconsMap.mdiIcons]) da seção "Indicar para".
  static const iconeBuscarUsuario = 'account-search-outline';
  static const iconeAdicionarUsuario = 'account-plus-outline';

  @override
  State<VersiculoIndicacaoSheet> createState() => _VersiculoIndicacaoSheetState();
}

class _VersiculoIndicacaoSheetState extends State<VersiculoIndicacaoSheet> {
  final _comentario = TextEditingController();
  final _busca = TextEditingController();
  Timer? _esperaBusca;

  /// `vindId` cujo comentário já foi copiado para o campo; evita sobrescrever o que o usuário digita.
  int? _comentarioDe;

  BibliaLeituraViewmodel get _vm => widget.viewModel;

  @override
  void dispose() {
    _esperaBusca?.cancel();
    _busca.dispose();
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
    for (final Command command in [
      _vm.indicacoesCommand,
      _vm.indicarCommand,
      _vm.removerIndicacaoCommand,
      _vm.adicionarIndicadoCommand,
      _vm.removerIndicadoCommand,
    ]) {
      if (command.error) return BibliaLeituraView.mensagemErro(command.result);
    }
    return _vm.erroBuscaUsuarios;
  }

  /// Busca usuários depois de uma pausa na digitação; texto curto só limpa o resultado.
  void _onBuscaAlterada(String texto) {
    _esperaBusca?.cancel();
    if (texto.trim().length < _vm.buscaUsuarioMinimo) {
      _vm.limparBuscaUsuarios();
      return;
    }
    _esperaBusca = Timer(VersiculoIndicacaoSheet.esperaBusca, () => _vm.buscarUsuarios(texto));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _vm,
        _vm.indicarCommand,
        _vm.removerIndicacaoCommand,
        _vm.indicacoesCommand,
        _vm.adicionarIndicadoCommand,
        _vm.removerIndicadoCommand,
      ]),
      builder: (context, _) {
        final versiculo = _vm.versiculoSelecionado;
        if (versiculo == null) return const SizedBox.shrink();

        _sincronizarComentario();
        final indicacoes = _vm.indicacoes;
        final minha = indicacoes?.minha;
        final gravando = _vm.indicarCommand.running || _vm.removerIndicacaoCommand.running;
        final erro = _erro();

        // Folha alta e rolável: versículo longo, comentário extenso ou teclado aberto não cortam o conteúdo.
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: VersiculoIndicacaoSheet.alturaInicial,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text(versiculo.referencia, style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(versiculo.versTexto, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
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
                    minLines: 4,
                    maxLines: 10,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: strings.translate('comentarioOpcional'),
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // OverflowBar empilha os botões quando não cabem lado a lado.
                  OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowAlignment: OverflowBarAlignment.end,
                    overflowSpacing: 8,
                    children: [
                      if (minha != null)
                        TextButton.icon(
                          onPressed: gravando ? null : _vm.removerIndicacaoCommand.execute,
                          icon: BibliaLeituraView.icone(BibliaLeituraView.iconeRemover, Icons.delete_outline),
                          label: Text(strings.translate('removerIndicacao')),
                        )
                      else
                        const SizedBox.shrink(),
                      FilledButton.icon(
                        onPressed: gravando ? null : () => _vm.indicarCommand.execute(_comentario.text),
                        icon: BibliaLeituraView.icone(BibliaLeituraView.iconeIndicar, Icons.thumb_up_outlined),
                        label: Text(strings.translate(minha == null ? 'indicarVersiculo' : 'atualizarIndicacao')),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  ..._indicarPara(minha != null, gravando, strings),
                ],
                if (erro != null) ...[
                  const SizedBox(height: 8),
                  Text(strings.translate(erro), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Seção "Indicar para": destinatários da indicação (removíveis) e busca de usuários para adicionar. Antes de
  /// indicar o versículo, só mostra a orientação.
  List<Widget> _indicarPara(bool indicado, bool gravando, AppLocalizations strings) {
    final textTheme = Theme.of(context).textTheme;
    final titulo = Text(strings.translate('indicarPara'), style: textTheme.titleMedium);
    if (!indicado) {
      return [
        titulo,
        const SizedBox(height: 4),
        Text(strings.translate('indiqueParaAdicionarUsuarios'), style: textTheme.bodySmall),
      ];
    }

    final ocupado = gravando || _vm.adicionarIndicadoCommand.running || _vm.removerIndicadoCommand.running;
    final encontrados = _vm.usuariosEncontrados;
    final buscou = _busca.text.trim().length >= _vm.buscaUsuarioMinimo;

    return [
      titulo,
      const SizedBox(height: 8),
      if (_vm.indicados.isEmpty)
        Text(strings.translate('nenhumUsuarioIndicado'), style: textTheme.bodySmall)
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final indicado in _vm.indicados)
              InputChip(
                label: Text(
                  _vm.nomeUsuario(udetNome: indicado.udetNome, udetUsuario: indicado.udetUsuario) ??
                      '#${indicado.usuaId}',
                ),
                tooltip: indicado.udetUsuario == null ? null : '@${indicado.udetUsuario}',
                deleteButtonTooltipMessage: strings.translate('removerUsuarioIndicado'),
                onDeleted: ocupado ? null : () => _vm.removerIndicadoCommand.execute(indicado),
              ),
          ],
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _busca,
        enabled: !ocupado,
        autocorrect: false,
        textInputAction: TextInputAction.search,
        onChanged: _onBuscaAlterada,
        decoration: InputDecoration(
          labelText: strings.translate('buscarUsuario'),
          hintText: strings.translate('buscarUsuarioDica'),
          prefixIcon: BibliaLeituraView.icone(VersiculoIndicacaoSheet.iconeBuscarUsuario, Icons.person_search_outlined),
          border: const OutlineInputBorder(),
        ),
      ),
      if (_vm.buscandoUsuarios) const LinearProgressIndicator(),
      if (buscou && !_vm.buscandoUsuarios && encontrados.isEmpty && _vm.erroBuscaUsuarios == null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(strings.translate('nenhumUsuarioEncontrado'), style: textTheme.bodySmall),
        ),
      for (final usuario in encontrados)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_vm.nomeUsuario(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario) ?? ''),
          subtitle: usuario.udetUsuario == null ? null : Text('@${usuario.udetUsuario}'),
          trailing: IconButton(
            tooltip: strings.translate('adicionarUsuarioIndicado'),
            onPressed: ocupado ? null : () => _vm.adicionarIndicadoCommand.execute(usuario),
            icon: BibliaLeituraView.icone(VersiculoIndicacaoSheet.iconeAdicionarUsuario, Icons.person_add_alt_outlined),
          ),
        ),
    ];
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
