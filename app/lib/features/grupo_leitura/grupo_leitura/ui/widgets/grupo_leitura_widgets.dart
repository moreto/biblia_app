import 'package:app/config/command.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../../data/model/leitura/leitura_model.dart';
import '../grupo_leitura_view.dart';

/// Seleção do grupo no topo das abas "Participantes", "Agenda" e "Atividades" (mesmo estilo das abas da comunidade).
class GrupoLeituraSelecao extends StatelessWidget {
  const GrupoLeituraSelecao({
    super.key,
    required this.grupos,
    required this.selecionado,
    required this.habilitado,
    required this.onSelecionar,
  });

  final List<LeituraModel> grupos;
  final int? selecionado;
  final bool habilitado;
  final ValueChanged<int> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<int>(
        key: ValueKey(selecionado),
        initialValue: selecionado,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('grupoLeitura'),
          prefixIcon: GrupoLeituraView.icone(GrupoLeituraView.iconeGrupo, Icons.menu_book_outlined),
        ),
        items: [
          for (final grupo in grupos)
            DropdownMenuItem(
              value: grupo.leitId,
              child: Text(grupo.leitNome, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: habilitado ? (leitId) => leitId == null ? null : onSelecionar(leitId) : null,
      ),
    );
  }
}

/// Erro do primeiro carregamento da aba: a mensagem e "Tentar novamente".
class GrupoLeituraErro extends StatelessWidget {
  const GrupoLeituraErro({super.key, required this.command});

  final Command0 command;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(GrupoLeituraView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: GrupoLeituraView.icone(GrupoLeituraView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista vazia: ícone e mensagem (chave de tradução), rolável para o "puxar para atualizar".
class GrupoLeituraVazio extends StatelessWidget {
  const GrupoLeituraVazio({super.key, required this.icone, required this.fallback, required this.mensagem});

  final String icone;
  final IconData fallback;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GrupoLeituraView.icone(icone, fallback, size: 48, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context).translate(mensagem), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item de menu de ações (ícone e texto), no mesmo formato das telas de comunidade.
PopupMenuItem<T> grupoLeituraMenuItem<T>(T valor, Widget icone, String texto) => PopupMenuItem(
  value: valor,
  child: ListTile(contentPadding: EdgeInsets.zero, leading: icone, title: Text(texto)),
);
