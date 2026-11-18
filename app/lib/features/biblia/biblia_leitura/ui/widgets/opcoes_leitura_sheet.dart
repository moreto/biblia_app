import 'package:app/config/leitura_preferencia.dart';
import 'package:app/config/narracao_voz.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../use_case/biblia_leitura_usecase.dart';
import '../biblia_leitura_viewmodel.dart';

/// Conteúdo do sheet "Opções de leitura", aberto pelo botão central da navegação da leitura: marcar o capítulo
/// (só com login), versão, tamanho da fonte, brilho da tela (se o aparelho permitir) e tema.
class OpcoesLeituraSheet extends StatefulWidget {
  const OpcoesLeituraSheet({super.key, required this.viewModel});

  final BibliaLeituraViewmodel viewModel;

  @override
  State<OpcoesLeituraSheet> createState() => _OpcoesLeituraSheetState();
}

class _OpcoesLeituraSheetState extends State<OpcoesLeituraSheet> {
  BibliaLeituraViewmodel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.carregarBrilho();
    if (_vm.narracaoDisponivel && _vm.vozesCommand.result == null) _vm.vozesCommand.execute();
  }

  /// Fecha o sheet e marca (ou desmarca) o capítulo; a confirmação aparece na tela da leitura.
  void _marcarCapitulo() {
    Navigator.of(context).pop();
    _vm.marcarLidoCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.marcarLidoCommand, _vm.versaoCommand, _vm.vozesCommand]),
      builder: (context, _) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_vm.logado) ...[
              _botaoMarcar(strings),
              _titulo(strings.translate('aoPassarPagina')),
              _marcarAoPassar(strings),
              const SizedBox(height: 16),
            ],
            _versao(strings),
            const SizedBox(height: 16),
            _titulo(strings.translate('tamanhoFonte')),
            _fonte(),
            if (_vm.brilho != null) ...[_titulo(strings.translate('brilho')), _brilho()],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.translate('mostrarSetasNavegacao')),
              value: _vm.mostrarSetas,
              onChanged: _vm.setMostrarSetas,
            ),
            if (_vm.narracaoDisponivel) ...[_titulo(strings.translate('narracao')), _narracao(strings)],
            _titulo(strings.translate('tema')),
            _tema(strings),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(texto, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _botaoMarcar(AppLocalizations strings) {
    final lido = _vm.lidoAtual?.completo ?? false;
    final marcando = _vm.marcarLidoCommand.running;
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: marcando || _vm.versiculos == null ? null : _marcarCapitulo,
      icon: marcando
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(lido ? Icons.check_circle : Icons.check_circle_outline),
      label: Text(strings.translate(lido ? 'desmarcarCapituloLido' : 'marcarCapituloLido')),
    );
  }

  /// Ao passar para o próximo capítulo: não marcar, perguntar ou marcar o anterior como lido.
  Widget _marcarAoPassar(AppLocalizations strings) => SegmentedButton<MarcarAoPassar>(
    showSelectedIcon: false,
    style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
    segments: [
      for (final (valor, chave) in [
        (MarcarAoPassar.nunca, 'naoMarcar'),
        (MarcarAoPassar.perguntar, 'perguntar'),
        (MarcarAoPassar.sempre, 'marcarLido'),
      ])
        ButtonSegment(
          value: valor,
          label: Text(strings.translate(chave), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
    selected: {_vm.marcarAoPassar},
    onSelectionChanged: (valores) => _vm.setMarcarAoPassar(valores.first),
  );

  /// Voz (as em português do aparelho, da melhor para a pior), velocidade e "Ouvir exemplo".
  Widget _narracao(AppLocalizations strings) {
    final vozes = _vm.vozes;
    final voz = _vm.vozNarracao;
    String rotulo(VozNarracao v) => [
      v.nome,
      strings.translate(BibliaLeituraUseCase.rotuloQualidade(v)),
      if (v.online) strings.translate('vozOnline'),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_vm.vozesCommand.running)
          const LinearProgressIndicator()
        else if (vozes.isEmpty)
          Text(strings.translate('nenhumaVozPortugues'), style: Theme.of(context).textTheme.bodyMedium)
        else
          DropdownButtonFormField<String>(
            key: ValueKey(voz?.nome),
            initialValue: voz?.nome,
            isExpanded: true,
            decoration: InputDecoration(labelText: strings.translate('voz'), border: const OutlineInputBorder()),
            items: [
              for (final v in vozes)
                DropdownMenuItem(
                  value: v.nome,
                  child: Text(rotulo(v), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (nome) {
              final escolhida = vozes.where((v) => v.nome == nome).firstOrNull;
              if (escolhida != null) _vm.setVozNarracao(escolhida);
            },
          ),
        Row(
          children: [
            Tooltip(message: strings.translate('maisDevagar'), child: const Icon(Icons.slow_motion_video, size: 20)),
            Expanded(
              child: Slider(
                key: const ValueKey('velocidadeNarracao'),
                value: _vm.velocidadeNarracao,
                min: BibliaLeituraUseCase.velocidadeMinima,
                max: BibliaLeituraUseCase.velocidadeMaxima,
                divisions: 8,
                label: '${(_vm.velocidadeNarracao / 0.5 * 100).round()}%',
                onChanged: _vm.setVelocidadeNarracao,
              ),
            ),
            Tooltip(message: strings.translate('maisRapido'), child: const Icon(Icons.speed, size: 22)),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.translate('narracaoContinua')),
          subtitle: Text(strings.translate('narracaoContinuaDica')),
          value: _vm.narracaoContinua,
          onChanged: _vm.setNarracaoContinua,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _vm.ouvirExemplo,
            icon: const Icon(Icons.play_arrow),
            label: Text(strings.translate('ouvirExemplo')),
          ),
        ),
      ],
    );
  }

  Widget _versao(AppLocalizations strings) {
    final versao = _vm.versao;
    return DropdownButtonFormField<int>(
      key: ValueKey(versao?.versaId),
      initialValue: versao?.versaId,
      isExpanded: true,
      decoration: InputDecoration(labelText: strings.translate('versao'), border: const OutlineInputBorder()),
      items: [
        for (final v in _vm.versoes)
          DropdownMenuItem(
            value: v.versaId,
            child: Text('${v.versaCodigo} · ${v.versaNome}', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: _vm.versaoCommand.running
          ? null
          : (versaId) {
              final escolhida = _vm.versoes.where((v) => v.versaId == versaId).firstOrNull;
              if (escolhida != null && escolhida.versaId != versao?.versaId) _vm.versaoCommand.execute(escolhida);
            },
    );
  }

  Widget _fonte() => Row(
    children: [
      Text('A−', style: Theme.of(context).textTheme.bodySmall),
      Expanded(
        child: Slider(
          key: const ValueKey('tamanhoFonte'),
          value: _vm.escalaFonte,
          min: BibliaLeituraUseCase.escalaFonteMinima,
          max: BibliaLeituraUseCase.escalaFonteMaxima,
          divisions: 8,
          label: '${(_vm.escalaFonte * 100).round()}%',
          onChanged: _vm.setEscalaFonte,
        ),
      ),
      Text('A+', style: Theme.of(context).textTheme.titleLarge),
    ],
  );

  Widget _brilho() => Row(
    children: [
      const Icon(Icons.brightness_low, size: 20),
      Expanded(
        child: Slider(key: const ValueKey('brilho'), value: _vm.brilho!, onChanged: _vm.setBrilho),
      ),
      const Icon(Icons.brightness_high, size: 24),
    ],
  );

  /// Sistema, Claro, Creme e Escuro. Só os nomes (sem ícones), para os quatro caberem na largura do celular.
  Widget _tema(AppLocalizations strings) => SegmentedButton<TemaApp>(
    showSelectedIcon: false,
    style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
    segments: [
      for (final tema in TemaApp.values)
        ButtonSegment(
          value: tema,
          label: Text(strings.translate(tema.name), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
    selected: {_vm.tema},
    onSelectionChanged: (temas) => _vm.setTema(temas.first),
  );
}
