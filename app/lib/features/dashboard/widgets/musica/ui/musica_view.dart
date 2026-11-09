import 'package:app/config/icons_map.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:service/service.dart';

import '../../../../../data/model/musica/musica_model.dart';
import 'musica_viewmodel.dart';

/// Widget da dashboard: card com uma música sorteada (`GET /v1/musica/aleatoria`).
///
/// - Carregando sem música: indicador de progresso dentro do card.
/// - Com música: nome, artista e gênero, a inspiração bíblica (quando houver, com [iconeInspiracao]),
///   botões "Ouvir em" para cada plataforma com link e o botão "Outra música", que faz um novo sorteio
///   mantendo a música atual visível até a resposta.
/// - Erro sem música carregada: mensagem traduzida e "Tentar novamente". Erro em um novo sorteio ou ao
///   abrir um link mantém a música atual e mostra um SnackBar.
///
/// Ícones (em [IconsMap.mdiIcons]): [iconeCard], [iconeArtista], [iconeInspiracao], [iconeOutra],
/// [iconeTentarNovamente] e o de cada [MusicaPlataforma] (`spotify`, `music-circle`, `apple`).
class MusicaView extends StatefulWidget {
  const MusicaView({super.key, required this.viewModel});

  final MusicaViewmodel viewModel;

  /// Chave do ícone do cabeçalho do card.
  static const iconeCard = 'music-note';

  /// Chave do ícone ao lado do artista.
  static const iconeArtista = 'account-music-outline';

  /// Chave do ícone da inspiração bíblica.
  static const iconeInspiracao = 'format-quote-open';

  /// Chave do ícone do botão "Outra música".
  static const iconeOutra = 'autorenew';

  /// Chave do ícone do botão "Tentar novamente".
  static const iconeTentarNovamente = 'refresh';

  @override
  State<MusicaView> createState() => _MusicaViewState();
}

class _MusicaViewState extends State<MusicaView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.aleatoriaCommand.addListener(_onResult);
    widget.viewModel.abrirLinkCommand.addListener(_onAbrirLinkResult);
  }

  @override
  void didUpdateWidget(covariant MusicaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.viewModel.aleatoriaCommand.removeListener(_onResult);
    oldWidget.viewModel.abrirLinkCommand.removeListener(_onAbrirLinkResult);
    widget.viewModel.aleatoriaCommand.addListener(_onResult);
    widget.viewModel.abrirLinkCommand.addListener(_onAbrirLinkResult);
  }

  @override
  void dispose() {
    widget.viewModel.aleatoriaCommand.removeListener(_onResult);
    widget.viewModel.abrirLinkCommand.removeListener(_onAbrirLinkResult);
    super.dispose();
  }

  /// Só o erro de um novo sorteio (com música já exibida) gera SnackBar; o erro do primeiro
  /// carregamento aparece dentro do card, em [_erro].
  void _onResult() {
    final command = widget.viewModel.aleatoriaCommand;
    if (command.error && widget.viewModel.musica != null) {
      _mostrarErro(command.result);
      command.clearResult();
    } else if (command.completed) {
      command.clearResult();
    }
  }

  void _onAbrirLinkResult() {
    final command = widget.viewModel.abrirLinkCommand;
    if (command.error) {
      _mostrarErro(command.result);
      command.clearResult();
    } else if (command.completed) {
      command.clearResult();
    }
  }

  void _mostrarErro(Result? result) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate(_mensagemErro(result)))));
  }

  String _mensagemErro(Result? result) {
    if (result case Error(error: final exception)) {
      if (exception is HandledException) return exception.message;
      if (exception is HttpServiceException) return exception.message ?? kDefaultAppError;
    }
    return kDefaultAppError;
  }

  /// Ícone de [IconsMap.mdiIcons] pela chave; usa [fallback] se a chave não estiver mapeada.
  Widget _icone(String chave, IconData fallback, {Color? color, double? size}) =>
      Icon(IconsMap.mdiIcons[chave] ?? fallback, color: color, size: size);

  Widget _carregando() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _erro(AppLocalizations strings) {
    final command = widget.viewModel.aleatoriaCommand;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(strings.translate(_mensagemErro(command.result)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: command.running ? null : command.execute,
            icon: _icone(MusicaView.iconeTentarNovamente, Icons.refresh),
            label: Text(strings.translate('tentarNovamente')),
          ),
        ],
      ),
    );
  }

  Widget _inspiracao(String texto) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icone(MusicaView.iconeInspiracao, Icons.format_quote, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  Widget _plataformas(AppLocalizations strings) {
    final viewModel = widget.viewModel;
    final abrindo = viewModel.abrirLinkCommand.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.translate('ouvirEm'), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final link in viewModel.links)
              ActionChip(
                avatar: _icone(link.plataforma.icone, Icons.music_note, size: 18),
                label: Text(link.plataforma.nome),
                onPressed: abrindo ? null : () => viewModel.abrirLinkCommand.execute(link),
              ),
          ],
        ),
      ],
    );
  }

  Widget _conteudo(MusicaModel musica, AppLocalizations strings) {
    final viewModel = widget.viewModel;
    final theme = Theme.of(context);
    final sorteando = viewModel.aleatoriaCommand.running;
    final inspiracao = viewModel.inspiracao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(musica.musiNome, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            _icone(MusicaView.iconeArtista, Icons.person_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${musica.musiArtista} · ${musica.mgenNome}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (inspiracao != null) ...[const SizedBox(height: 12), _inspiracao(inspiracao)],
        if (viewModel.links.isNotEmpty) ...[const SizedBox(height: 12), _plataformas(strings)],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: sorteando ? null : viewModel.aleatoriaCommand.execute,
            icon: sorteando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : _icone(MusicaView.iconeOutra, Icons.autorenew),
            label: Text(strings.translate('outraMusica')),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    final strings = AppLocalizations.of(context);
    final viewModel = widget.viewModel;
    final musica = viewModel.musica;
    final theme = Theme.of(context);

    final Widget corpo;
    if (musica != null) {
      corpo = _conteudo(musica, strings);
    } else if (viewModel.aleatoriaCommand.error) {
      corpo = _erro(strings);
    } else {
      corpo = _carregando();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _icone(MusicaView.iconeCard, Icons.music_note_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(strings.translate('musica'), style: theme.textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 12),
            corpo,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: widget.viewModel, builder: (context, child) => _card());
  }
}
