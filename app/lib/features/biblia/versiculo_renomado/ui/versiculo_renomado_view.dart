import 'package:app/config/icons_map.dart';
import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service/service.dart';

import '../../../../data/model/biblia/versiculo_renomado_model.dart';
import '../../../../routing/routes.dart';
import 'versiculo_renomado_viewmodel.dart';

/// Versículos de um renomado (`GET /v1/versiculo-renomado/:renoId/:versaId`), na versão escolhida pelo usuário.
///
/// - Topo: seleção da versão (`/v1/versao`), a mesma da leitura; trocar aqui também troca lá.
/// - Cabeçalho com o texto de apresentação do renomado, quando houver.
/// - Cada versículo mostra a referência e o texto; tocar abre a leitura no capítulo, com o versículo destacado.
/// - Primeiro carregamento: progresso; se falhar, mensagem com "Tentar novamente". Erro ao trocar a versão vira
///   SnackBar e mantém a lista.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeVersao], [iconeAbrirLeitura], [iconeVazio] e [iconeTentarNovamente].
class VersiculoRenomadoView extends StatefulWidget {
  const VersiculoRenomadoView({super.key, required this.viewModel});

  final VersiculoRenomadoViewmodel viewModel;

  static const iconeVersao = 'book-multiple';
  static const iconeAbrirLeitura = 'book-open-variant';
  static const iconeVazio = 'book-open-page-variant-outline';
  static const iconeTentarNovamente = 'refresh';

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
  State<VersiculoRenomadoView> createState() => _VersiculoRenomadoViewState();
}

class _VersiculoRenomadoViewState extends State<VersiculoRenomadoView> {
  VersiculoRenomadoViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.versaoCommand.addListener(_onResult);
  }

  @override
  void didUpdateWidget(covariant VersiculoRenomadoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.versaoCommand.removeListener(_onResult);
    _vm.versaoCommand.addListener(_onResult);
  }

  @override
  void dispose() {
    _vm.versaoCommand.removeListener(_onResult);
    super.dispose();
  }

  /// Erro na troca de versão vira SnackBar; o do carregamento inicial fica na tela, em [_erroCarregamento].
  void _onResult() {
    final command = _vm.versaoCommand;
    if (!command.error) return;

    final mensagem = VersiculoRenomadoView.mensagemErro(command.result);
    command.clearResult();
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(mensagem))));
  }

  void _abrirLeitura(VersiculoRenomadoModel versiculo) {
    final destino = _vm.destino(versiculo);
    context.push(Uri(path: Routes.bibliaLeitura, queryParameters: destino.toQuery()).toString());
  }

  Widget _erroCarregamento(AppLocalizations strings) {
    final command = _vm.carregarCommand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.translate(VersiculoRenomadoView.mensagemErro(command.result)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: command.running ? null : command.execute,
              icon: VersiculoRenomadoView.icone(VersiculoRenomadoView.iconeTentarNovamente, Icons.refresh),
              label: Text(strings.translate('tentarNovamente')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _versaoSelecao(AppLocalizations strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<int>(
        key: ValueKey(_vm.versao?.versaId),
        initialValue: _vm.versao?.versaId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: strings.translate('versao'),
          prefixIcon: VersiculoRenomadoView.icone(VersiculoRenomadoView.iconeVersao, Icons.library_books_outlined),
        ),
        items: [
          for (final versao in _vm.versoes)
            DropdownMenuItem(
              value: versao.versaId,
              child: Text('${versao.versaCodigo} · ${versao.versaNome}', overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _vm.versaoCommand.running
            ? null
            : (versaId) {
                final versao = _vm.versoes.where((v) => v.versaId == versaId).firstOrNull;
                if (versao != null) _vm.versaoCommand.execute(versao);
              },
      ),
    );
  }

  Widget _apresentacao(String texto) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
      ),
    );
  }

  Widget _vazio(AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          VersiculoRenomadoView.icone(
            VersiculoRenomadoView.iconeVazio,
            Icons.menu_book_outlined,
            size: 48,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          Text(strings.translate('nenhumVersiculoRenomado'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _versiculo(VersiculoRenomadoModel versiculo, AppLocalizations strings) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirLeitura(versiculo),
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
                      versiculo.referencia,
                      style: textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(versiculo.versTexto, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],
                ),
              ),
              IconButton(
                tooltip: strings.translate('abrirNaLeitura'),
                onPressed: () => _abrirLeitura(versiculo),
                icon: VersiculoRenomadoView.icone(
                  VersiculoRenomadoView.iconeAbrirLeitura,
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

  Widget _lista(List<VersiculoRenomadoModel> versiculos, AppLocalizations strings) {
    final texto = _vm.renomado?.renoTexto;
    final cabecalho = <Widget>[
      if (_vm.versoes.isNotEmpty) _versaoSelecao(strings),
      if (texto != null && texto.isNotEmpty) _apresentacao(texto),
    ];

    return Column(
      children: [
        if (_vm.versaoCommand.running) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: cabecalho.length + (versiculos.isEmpty ? 1 : versiculos.length),
            itemBuilder: (context, index) {
              if (index < cabecalho.length) return cabecalho[index];
              if (versiculos.isEmpty) return _vazio(strings);
              return _versiculo(versiculos[index - cabecalho.length], strings);
            },
          ),
        ),
      ],
    );
  }

  Widget _screen() {
    final strings = AppLocalizations.of(context);
    final versiculos = _vm.versiculos;

    final Widget body;
    if (versiculos == null && _vm.carregarCommand.running) {
      body = const Loading();
    } else if (versiculos == null) {
      body = _erroCarregamento(strings);
    } else {
      body = _lista(versiculos, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_vm.renomado?.renoNome ?? strings.translate('versiculosRenomado')),
        elevation: 0,
        actions: const [ThemeModeButton(), OrientationButton()],
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _vm, builder: (context, child) => _screen());
  }
}
