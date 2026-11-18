import 'dart:async';

import 'package:app/config/dialog_sheet.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../grupo_leitura/ui/grupo_leitura_view.dart';
import '../grupo_leitura_participante_viewmodel.dart';

/// "Adicionar participante" (no `DialogBottomSheet`, [show]) ao grupo selecionado ([grupoNome] no topo): busca por
/// nome ou nome de usuário (`/v1/usuario/busca`, a partir de 2 caracteres, [esperaBusca] depois da última tecla) e
/// lista os encontrados que ainda não participam (nem o dono); o botão de cada um executa o `adicionarCommand` do
/// [viewModel]. O diálogo continua aberto para adicionar outros; "Fechar" encerra.
///
/// Ícones (em `IconsMap.mdiIcons`): [iconeBuscar] e [iconeAdicionar].
class GrupoLeituraParticipanteAdicionarDialog extends StatefulWidget {
  const GrupoLeituraParticipanteAdicionarDialog({super.key, required this.viewModel, required this.grupoNome});

  final GrupoLeituraParticipanteViewmodel viewModel;
  final String grupoNome;

  static const esperaBusca = Duration(milliseconds: 400);
  static const iconeBuscar = 'account-search-outline';
  static const iconeAdicionar = 'account-plus-outline';

  static Future<void> show(
    BuildContext context, {
    required GrupoLeituraParticipanteViewmodel viewModel,
    required String grupoNome,
  }) {
    viewModel.limparBusca();
    return DialogSheet.show<void>(
      context,
      titulo: AppLocalizations.of(context).translate('adicionarParticipante'),
      conteudo: GrupoLeituraParticipanteAdicionarDialog(viewModel: viewModel, grupoNome: grupoNome),
    ).whenComplete(viewModel.limparBusca);
  }

  @override
  State<GrupoLeituraParticipanteAdicionarDialog> createState() => _GrupoLeituraParticipanteAdicionarDialogState();
}

class _GrupoLeituraParticipanteAdicionarDialogState extends State<GrupoLeituraParticipanteAdicionarDialog> {
  final _busca = TextEditingController();
  Timer? _esperaBusca;

  GrupoLeituraParticipanteViewmodel get _vm => widget.viewModel;

  @override
  void dispose() {
    _esperaBusca?.cancel();
    _busca.dispose();
    super.dispose();
  }

  void _onBuscaAlterada(String texto) {
    _esperaBusca?.cancel();
    _esperaBusca = Timer(GrupoLeituraParticipanteAdicionarDialog.esperaBusca, () => _vm.buscar(texto));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final ocupado = _vm.adicionarCommand.running;
        final encontrados = _vm.encontrados;
        final erro = _vm.erroBusca;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.grupoNome, style: textTheme.titleSmall),
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
                prefixIcon: GrupoLeituraView.icone(
                  GrupoLeituraParticipanteAdicionarDialog.iconeBuscar,
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
            for (final usuario in encontrados)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(_vm.iniciais(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario)),
                ),
                title: Text(_vm.nomeExibicao(udetNome: usuario.udetNome, udetUsuario: usuario.udetUsuario) ?? ''),
                subtitle: usuario.udetUsuario == null ? null : Text('@${usuario.udetUsuario}'),
                trailing: IconButton(
                  tooltip: strings.translate('adicionarParticipante'),
                  onPressed: ocupado ? null : () => _vm.adicionarCommand.execute(usuario),
                  icon: GrupoLeituraView.icone(
                    GrupoLeituraParticipanteAdicionarDialog.iconeAdicionar,
                    Icons.person_add_alt_outlined,
                  ),
                ),
              ),
            DialogSheet.acoes([
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(strings.translate('fechar'))),
            ]),
          ],
        );
      },
    );
  }
}
