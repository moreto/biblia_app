import 'package:app/config/orientation_button.dart';
import 'package:app/config/theme_mode_button.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:commons/commons.dart';
import 'package:components/components.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dialog_sheet.dart';
import '../../../biblia/biblia_leitura/ui/widgets/capitulo_chip.dart';
import '../../../biblia/biblia_leitura/use_case/biblia_leitura_usecase.dart';
import '../use_case/home_usecase.dart';
import 'home_viewmodel.dart';

/// Tela de entrada: menu hambúrguer (Drawer) na AppBar e, no corpo, os botões "Bíblia", "Continuar de onde parou"
/// e "Escolher capítulo", com o id do aparelho embaixo.
class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.viewModel});

  final HomeViewmodel viewModel;

  /// Abre a leitura e, ao voltar, relê o último capítulo aberto para o "Continuar".
  Future<void> _abrirLeitura(BuildContext context, [LeituraDestino? destino]) async {
    final rota = destino == null
        ? Routes.bibliaLeitura
        : Uri(path: Routes.bibliaLeitura, queryParameters: destino.toQuery()).toString();
    await context.push(rota);
    viewModel.atualizarContinuar();
  }

  /// Carrega livros e capítulos (só na primeira vez) e abre o seletor; o capítulo escolhido abre na leitura.
  Future<void> _escolherCapitulo(BuildContext context) async {
    final command = viewModel.seletorCommand;
    await command.execute();
    if (!context.mounted) return;

    final strings = AppLocalizations.of(context);
    final result = command.result;
    command.clearResult();
    final seletor = viewModel.seletor;
    if (seletor != null) {
      final destino = await DialogSheet.show<LeituraDestino>(
        context,
        titulo: '${strings.translate('escolherCapitulo')} · ${seletor.versao.versaCodigo}',
        conteudo: _SeletorCapituloSheet(seletor: seletor),
      );
      if (destino != null && context.mounted) await _abrirLeitura(context, destino);
    } else if (result case Error(error: final error)) {
      final mensagem = error is HandledException ? error.message : kDefaultAppError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.translate(mensagem))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      // Com `drawer`, a AppBar mostra o ícone do menu hambúrguer sozinha.
      appBar: AppBar(title: Text(strings.translate('home')), actions: const [OrientationButton(), ThemeModeButton()]),
      drawer: const _HomeDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // Os botões têm a mesma largura, limitada para não esticar em telas largas.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ListenableBuilder(
              listenable: Listenable.merge([viewModel, viewModel.seletorCommand, viewModel.idDispositivoCommand]),
              builder: (context, _) {
                final continuar = viewModel.continuar;
                final carregandoSeletor = viewModel.seletorCommand.running;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _abrirLeitura(context),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(strings.translate('biblia')),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Desabilitado até a leitura abrir o primeiro capítulo.
                    FilledButton.tonalIcon(
                      onPressed: continuar == null ? null : () => _abrirLeitura(context, continuar),
                      icon: const Icon(Icons.bookmark_outline),
                      label: Text(strings.translate('continuarDeOndeParou')),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: carregandoSeletor ? null : () => _escolherCapitulo(context),
                      icon: carregandoSeletor
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.format_list_numbered),
                      label: Text(strings.translate('escolherCapitulo')),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(child: _IdDispositivo(viewModel: viewModel)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Id do aparelho (Android ID / `identifierForVendor`), selecionável para poder copiar.
class _IdDispositivo extends StatelessWidget {
  const _IdDispositivo({required this.viewModel});

  final HomeViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    if (viewModel.idDispositivoCommand.running) {
      return const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }

    final id = viewModel.idDispositivo;
    if (id == null) {
      return Text(AppLocalizations.of(context).translate('dispositivoNaoIdentificado'), style: estilo);
    }
    return SelectableText(id, style: estilo, textAlign: TextAlign.center);
  }
}

/// Seletor de "Escolher capítulo": primeiro o livro, depois o capítulo. Fecha devolvendo o [LeituraDestino].
class _SeletorCapituloSheet extends StatefulWidget {
  const _SeletorCapituloSheet({required this.seletor});

  final SeletorCapitulo seletor;

  @override
  State<_SeletorCapituloSheet> createState() => _SeletorCapituloSheetState();
}

class _SeletorCapituloSheetState extends State<_SeletorCapituloSheet> {
  /// Livro escolhido; nulo mostra a lista de livros.
  int? _livrId;

  @override
  Widget build(BuildContext context) {
    final seletor = widget.seletor;
    final livrId = _livrId;
    // Altura fixa: a lista de livros é longa e o sheet não pode ocupar a tela toda.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: livrId == null ? _livros(seletor) : _capitulos(seletor, livrId),
    );
  }

  Widget _livros(SeletorCapitulo seletor) {
    return ListView.builder(
      itemCount: seletor.livros.length,
      itemBuilder: (context, index) {
        final livro = seletor.livros[index];
        return ListTile(
          title: Text(livro.livrNome),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _livrId = livro.livrId),
        );
      },
    );
  }

  Widget _capitulos(SeletorCapitulo seletor, int livrId) {
    final livro = seletor.livros.firstWhere((l) => l.livrId == livrId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: IconButton(
            tooltip: AppLocalizations.of(context).translate('voltar'),
            onPressed: () => setState(() => _livrId = null),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(livro.livrNome, style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final numero in seletor.capitulos[livrId] ?? const <int>[])
                  CapituloChip(
                    numero: numero,
                    lido: null,
                    onTap: () => Navigator.pop(
                      context,
                      LeituraDestino(versaId: seletor.versao.versaId, livrId: livrId, capiNumero: numero),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Menu lateral da tela de entrada.
class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Text(strings.translate('menus'), style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(strings.translate('home')),
              onTap: () {
                Navigator.pop(context);
                context.go(Routes.home);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(strings.translate('homeAntiga')),
              onTap: () {
                // Fecha o menu antes de abrir a tela, para ele não ficar aberto ao voltar.
                Navigator.pop(context);
                context.push(Routes.homeOld);
              },
            ),
          ],
        ),
      ),
    );
  }
}
