import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/versiculo_indicado_model.dart';
import '../../../../routing/routes.dart';
import 'versiculo_indicado_viewmodel.dart';

/// Tela "Indicações recebidas" (`Routes.versiculoIndicado`, tela própria, não é aba): versículos que outros usuários
/// indicaram ao usuário logado (`/v1/versiculo-indicacao-usuario/recebidas`), das mais recentes para as mais antigas.
///
/// - Cada card mostra a referência com a versão, o texto do versículo, o comentário de quem indicou (se houver),
///   quem indicou e quando. Tocar abre o versículo na leitura (`Routes.bibliaLeitura`), na versão indicada.
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Depois disso a lista é mantida, a
///   atualização (AppBar ou puxar para baixo) mostra uma barra de progresso e o erro vira SnackBar.
/// - Sem indicações: `nenhumaIndicacaoRecebida`.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeIndicacao], [iconeAbrirLeitura], [iconeComentario], [iconeQuem],
/// [iconeQuando] e [iconeAtualizar].
class VersiculoIndicadoView extends StatefulWidget {
  const VersiculoIndicadoView({super.key, required this.viewModel});

  final VersiculoIndicadoViewmodel viewModel;

  /// Ícone da tela (menu) e da lista vazia (o mesmo da indicação na leitura).
  static const iconeIndicacao = 'thumb-up-outline';
  static const iconeAbrirLeitura = 'book-open-variant';
  static const iconeComentario = 'comment-quote-outline';
  static const iconeQuem = 'account-outline';
  static const iconeQuando = 'clock-outline';
  static const iconeAtualizar = 'refresh';

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  static Widget icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  /// Mensagem (chave de tradução) do erro do comando.
  static String mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  @override
  State<VersiculoIndicadoView> createState() => _VersiculoIndicadoViewState();
}

class _VersiculoIndicadoViewState extends State<VersiculoIndicadoView> {
  VersiculoIndicadoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.carregarCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant VersiculoIndicadoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.carregarCommand.removeListener(_onResult);
    _vm.carregarCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    _vm.carregarCommand.removeListener(_onResult);
    super.dispose();
  }

  /// Erro de uma atualização (com lista já carregada) vira SnackBar; o do primeiro carregamento fica na tela.
  void _onResult() {
    final command = _vm.carregarCommand;
    if (!mounted || !command.error || _vm.recebidas == null) return;
    final mensagem = VersiculoIndicadoView.mensagemErro(command.result);
    command.clearResult();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  void _abrirLeitura(VersiculoIndicadoModel indicacao) {
    final destino = _vm.destino(indicacao);
    context.push(Uri(path: Routes.bibliaLeitura, queryParameters: destino.toQuery()).toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, _) => _screen());
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final command = _vm.carregarCommand;
    final recebidas = _vm.recebidas;

    final Widget body;
    if (recebidas == null && !command.error) {
      body = const Loading();
    } else if (recebidas == null) {
      body = _erroCarregamento(strings);
    } else {
      body = Column(
        children: [
          if (command.running) const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: command.execute,
              child: recebidas.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: constraints.maxHeight, child: _vazio(strings)),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: recebidas.length,
                      itemBuilder: (context, index) => _indicacao(recebidas[index], strings),
                    ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('indicacoesRecebidas')),
        elevation: 0,
        actions: [
          const ThemeModeButton(),
          const OrientationButton(),
          IconButton(
            tooltip: strings.translate('atualizar'),
            onPressed: command.running ? null : command.execute,
            icon: VersiculoIndicadoView.icone(VersiculoIndicadoView.iconeAtualizar, Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
      bottomNavigationBar: ViewBottomActions(
        backLabel: strings.translate('voltar'),
        hideActionsTooltip: strings.translate('ocultarAcoes'),
        showActionsTooltip: strings.translate('exibirAcoes'),
      ),
    );
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.carregarCommand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(VersiculoIndicadoView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: VersiculoIndicadoView.icone(VersiculoIndicadoView.iconeAtualizar, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VersiculoIndicadoView.icone(
              VersiculoIndicadoView.iconeIndicacao,
              Icons.thumb_up_outlined,
              size: 48,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(strings.translate('nenhumaIndicacaoRecebida'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Linha pequena com ícone (quem indicou, quando).
  Widget _detalhe(String icone, IconData fallback, String texto) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          VersiculoIndicadoView.icone(icone, fallback, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicacao(VersiculoIndicadoModel indicacao, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final comentario = _vm.comentario(indicacao);
    final quem = _vm.quemIndicou(indicacao);
    final data = _vm.data(indicacao);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirLeitura(indicacao),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vm.referencia(indicacao),
                      style: textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(indicacao.versTexto.trim(), style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                    if (comentario != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VersiculoIndicadoView.icone(
                              VersiculoIndicadoView.iconeComentario,
                              Icons.format_quote,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comentario,
                                style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (quem != null)
                      _detalhe(
                        VersiculoIndicadoView.iconeQuem,
                        Icons.person_outline,
                        '${strings.translate('indicadoPor')} $quem',
                      ),
                    if (data != null) _detalhe(VersiculoIndicadoView.iconeQuando, Icons.schedule, data),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.translate('abrirNaLeitura'),
                onPressed: () => _abrirLeitura(indicacao),
                icon: VersiculoIndicadoView.icone(
                  VersiculoIndicadoView.iconeAbrirLeitura,
                  Icons.menu_book,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
