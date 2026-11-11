import 'dart:async';

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../comunidade_usuario_view.dart';
import '../comunidade_usuario_viewmodel.dart';

/// Diálogo "Adicionar usuário" à comunidade selecionada ([comunidadeNome] no topo): busca por nome ou nome de
/// usuário (`/v1/usuario/busca`, a partir de `buscaMinimo` caracteres, [esperaBusca] depois da última tecla) e
/// lista os encontrados que ainda não estão na comunidade; o botão de cada um executa o `adicionarCommand` do
/// [viewModel]. O diálogo continua aberto para adicionar outros; "Fechar" encerra.
///
/// Ícones (em `IconsMap.mdiIcons`): [iconeBuscar] e [iconeAdicionar].
class ComunidadeUsuarioAdicionarDialog extends StatefulWidget {
  const ComunidadeUsuarioAdicionarDialog({super.key, required this.viewModel, required this.comunidadeNome});

  final ComunidadeUsuarioViewmodel viewModel;
  final String comunidadeNome;

  static const esperaBusca = Duration(milliseconds: 400);
  static const iconeBuscar = 'account-search-outline';
  static const iconeAdicionar = 'account-plus-outline';

  static Future<void> show(
    BuildContext context, {
    required ComunidadeUsuarioViewmodel viewModel,
    required String comunidadeNome,
  }) {
    viewModel.limparBusca();
    return showDialog<void>(
      context: context,
      builder: (context) => ComunidadeUsuarioAdicionarDialog(viewModel: viewModel, comunidadeNome: comunidadeNome),
    ).whenComplete(viewModel.limparBusca);
  }

  @override
  State<ComunidadeUsuarioAdicionarDialog> createState() => _ComunidadeUsuarioAdicionarDialogState();
}

class _ComunidadeUsuarioAdicionarDialogState extends State<ComunidadeUsuarioAdicionarDialog> {
  final _busca = TextEditingController();
  Timer? _esperaBusca;

  ComunidadeUsuarioViewmodel get _vm => widget.viewModel;

  @override
  void dispose() {
    _esperaBusca?.cancel();
    _busca.dispose();
    super.dispose();
  }

  void _onBuscaAlterada(String texto) {
    _esperaBusca?.cancel();
    _esperaBusca = Timer(ComunidadeUsuarioAdicionarDialog.esperaBusca, () => _vm.buscar(texto));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(strings.translate('adicionarUsuario')),
      content: SizedBox(
        width: 420,
        child: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            final ocupado = _vm.adicionarCommand.running;
            final encontrados = _vm.encontrados;
            final erro = _vm.erroBusca;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.comunidadeNome, style: textTheme.titleSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _busca,
                  autofocus: true,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  onChanged: _onBuscaAlterada,
                  onSubmitted: _vm.buscar,
                  decoration: InputDecoration(
                    labelText: strings.translate('buscarUsuario'),
                    hintText: strings.translate('buscarUsuarioDica'),
                    prefixIcon: ComunidadeUsuarioView.icone(
                      ComunidadeUsuarioAdicionarDialog.iconeBuscar,
                      Icons.person_search_outlined,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_vm.buscando || ocupado) const LinearProgressIndicator(),
                if (erro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      strings.translate(erro),
                      style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (_vm.buscou && !_vm.buscando && encontrados.isEmpty && erro == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(strings.translate('nenhumUsuarioEncontrado'), style: textTheme.bodySmall),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final usuario in encontrados)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(_vm.iniciais(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario)),
                          ),
                          title: Text(
                            _vm.nomeExibicao(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario) ?? '',
                          ),
                          subtitle: usuario.udetUsuario == null ? null : Text('@${usuario.udetUsuario}'),
                          trailing: IconButton(
                            tooltip: strings.translate('adicionarUsuario'),
                            onPressed: ocupado ? null : () => _vm.adicionarCommand.execute(usuario),
                            icon: ComunidadeUsuarioView.icone(
                              ComunidadeUsuarioAdicionarDialog.iconeAdicionar,
                              Icons.person_add_alt_outlined,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('fechar')))],
    );
  }
}
