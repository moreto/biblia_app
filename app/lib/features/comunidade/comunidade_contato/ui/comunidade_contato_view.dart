import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';

import '../../../../data/model/comunidade/comunidade_contato_model.dart';
import '../../comunidade/ui/comunidade_view.dart';
import '../use_case/comunidade_contato_usecase.dart';
import 'comunidade_contato_viewmodel.dart';

/// Ações do menu de cada contato.
enum _Acao { editar, excluir }

/// Aba "Contatos" da tela de comunidades: contatos da comunidade selecionada (`/v1/comunidade-contato/:comuId`).
///
/// - Topo: seleção da comunidade (as do usuário, na ordem de "Minhas comunidades").
/// - Cada contato é um card com os campos preenchidos (ícone, rótulo e valor; telefones formatados). Tocar num
///   campo abre o contato fora do app (ligação, WhatsApp, e-mail ou página); tocar no card edita ([onEditar]) e o
///   menu tem editar e excluir ([onExcluir]). A inclusão é pelo botão "Novo contato" da parte inferior da tela.
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida e
///   a atualização, a troca de comunidade, a gravação e a exclusão mostram uma barra de progresso.
/// - Sem contatos: `nenhumContatoCadastrado`; sem comunidades: `nenhumaComunidadeCadastrada`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeContato] e o [ContatoCampo.icone] de cada campo, além de
/// `ComunidadeView.iconeComunidade`, `ComunidadeView.iconeAcoes`, `ComunidadeView.iconeEditar` e
/// `ComunidadeView.iconeExcluir`.
class ComunidadeContatoView extends StatelessWidget {
  const ComunidadeContatoView({super.key, required this.viewModel, required this.onEditar, required this.onExcluir});

  final ComunidadeContatoViewmodel viewModel;
  final ValueChanged<ComunidadeContatoModel> onEditar;
  final ValueChanged<ComunidadeContatoModel> onExcluir;

  /// Ícone da aba e da lista vazia.
  static const iconeContato = 'card-account-phone-outline';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      ComunidadeView.icone(chave, fallback, color: color, size: size);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: viewModel, builder: (context, _) => _conteudo(context));
  }

  Widget _conteudo(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final command = viewModel.carregarCommand;
    final comunidades = viewModel.comunidades;

    if (comunidades == null && !command.error) return const Loading();
    if (comunidades == null) {
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
                icon: icone(ComunidadeView.iconeAtualizar, Icons.refresh),
                label: Text(strings.translate('tentarNovamente')),
              ),
            ],
          ),
        ),
      );
    }
    if (comunidades.isEmpty) {
      return Center(child: Text(strings.translate('nenhumaComunidadeCadastrada')));
    }

    final contatos = viewModel.contatos;
    return Column(
      children: [
        if (viewModel.ocupado) const LinearProgressIndicator(),
        _selecao(context, strings),
        Expanded(
          child: RefreshIndicator(
            onRefresh: command.execute,
            child: contatos.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: constraints.maxHeight, child: _vazio(context, strings)),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: contatos.length,
                    itemBuilder: (context, index) => _contato(context, strings, contatos[index]),
                  ),
          ),
        ),
      ],
    );
  }

  /// Seleção da comunidade, no topo (mesmo estilo da aba "Endereços").
  Widget _selecao(BuildContext context, AppLocalizations strings) {
    final selecionada = viewModel.selecionada?.comunidade.comuId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<int>(
        key: ValueKey(selecionada),
        initialValue: selecionada,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('comunidade'),
          prefixIcon: icone(ComunidadeView.iconeComunidade, Icons.groups_outlined),
        ),
        items: [
          for (final resumo in viewModel.comunidades ?? const [])
            DropdownMenuItem(
              value: resumo.comunidade.comuId,
              child: Text(resumo.comunidade.comuNome, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: viewModel.ocupado ? null : (comuId) => comuId == null ? null : viewModel.selecionar(comuId),
      ),
    );
  }

  Widget _vazio(BuildContext context, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icone(iconeContato, Icons.contact_phone_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumContatoCadastrado'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _contato(BuildContext context, AppLocalizations strings, ComunidadeContatoModel contato) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final habilitado = !viewModel.ocupado;
    final abrindo = viewModel.acessarCommand.running;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitado ? () => onEditar(contato) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: icone(iconeContato, Icons.contact_phone_outlined, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (campo, valor) in viewModel.preenchidos(contato))
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: icone(campo.icone, Icons.contact_page_outlined, color: scheme.primary),
                        title: Text(
                          viewModel.exibicao(campo, valor),
                          style: textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(strings.translate(campo.rotulo)),
                        onTap: !abrindo && viewModel.acessivel(campo, valor)
                            ? () => viewModel.acessarCommand.execute((campo, valor))
                            : null,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_Acao>(
                tooltip: strings.translate('acoes'),
                enabled: habilitado,
                icon: icone(ComunidadeView.iconeAcoes, Icons.more_vert),
                onSelected: (acao) => switch (acao) {
                  _Acao.editar => onEditar(contato),
                  _Acao.excluir => onExcluir(contato),
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _Acao.editar,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: icone(ComunidadeView.iconeEditar, Icons.edit_outlined),
                      title: Text(strings.translate('editar')),
                    ),
                  ),
                  PopupMenuItem(
                    value: _Acao.excluir,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: icone(ComunidadeView.iconeExcluir, Icons.delete_outline, color: scheme.error),
                      title: Text(strings.translate('excluir')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
