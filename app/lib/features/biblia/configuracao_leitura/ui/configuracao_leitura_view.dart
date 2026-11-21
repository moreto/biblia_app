import 'package:app/config/dialog_sheet.dart';
import 'package:app/config/icons_map.dart';
import 'package:app/config/leitura_preferencia.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/routing/routes.dart';
import 'package:components/components.dart' show HighlightColor, ReadingColors;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import '../../biblia_leitura/ui/widgets/login_necessario_sheet.dart';
import '../../biblia_leitura/ui/widgets/tags_leitura_sheet.dart';
import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'configuracao_leitura_viewmodel.dart';
import 'nomes_voz.dart';

/// Configurações de leitura (`/configuracoes-leitura`), abertas pelo livro com engrenagem da leitura. Tudo aqui
/// vale só na leitura.
///
/// Como as configurações do sistema: cada linha mostra o nome e o valor atual; tocar abre o ajuste num sheet de
/// baixo (fonte, brilho e velocidade com slider; tema e orientação como lista) ou uma tela própria (versão em
/// `/versao-biblia`, voz em `/voz-narracao`). Só os liga/desliga ficam na linha. Grupos:
/// - Texto: versão e tamanho da fonte (com prévia);
/// - Aparência: tema, orientação, brilho (se o aparelho permitir) e setas ‹ ›;
/// - Narração: voz, velocidade, narração contínua e "Ouvir exemplo";
/// - Anotações: "Gerenciar tags";
/// - "Restaurar padrão" (também na AppBar).
///
/// Usa o viewmodel da leitura aberta ([leitura], que vai no `extra` da rota) para tudo mudar na leitura na hora;
/// a orientação fica no [viewModel].
class ConfiguracaoLeituraView extends StatefulWidget {
  const ConfiguracaoLeituraView({super.key, required this.viewModel, required this.leitura});

  final ConfiguracaoLeituraViewmodel viewModel;
  final BibliaLeituraViewmodel leitura;

  @override
  State<ConfiguracaoLeituraView> createState() => _ConfiguracaoLeituraViewState();
}

class _ConfiguracaoLeituraViewState extends State<ConfiguracaoLeituraView> {
  BibliaLeituraViewmodel get _vm => widget.leitura;

  static const _orientacoes = [
    (OrientacaoLeitura.automatica, 'orientacaoAutomatica', Icon(Icons.screen_rotation_outlined)),
    (OrientacaoLeitura.retrato, 'retrato', Icon(Icons.stay_current_portrait)),
    (OrientacaoLeitura.paisagem, 'paisagem', Icon(Icons.stay_current_landscape)),
  ];

  static const _temas = [
    (TemaApp.sistema, 'temaDoApp', Icon(Icons.brightness_auto_outlined)),
    (TemaApp.claro, 'claro', Icon(Icons.light_mode_outlined)),
    (TemaApp.creme, 'creme', Icon(Icons.local_cafe_outlined)),
    (TemaApp.escuro, 'escuro', Icon(Icons.dark_mode_outlined)),
  ];

  /// Bolinha com a cor do marca-texto (do tema da leitura padrão, o do app).
  Widget _bolinha(HighlightColor cor, {double tamanho = 24}) => Container(
    width: tamanho,
    height: tamanho,
    decoration: BoxDecoration(
      color: Theme.of(context).extension<ReadingColors>()?.highlight(cor),
      shape: BoxShape.circle,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
  );

  @override
  void initState() {
    super.initState();
    _vm.carregarBrilho();
    if (_vm.narracaoDisponivel && _vm.vozesCommand.result == null) _vm.vozesCommand.execute();
  }

  static String _porcento(double valor) => '${(valor * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.translate('configuracoesLeitura')),
        actions: [
          IconButton(
            tooltip: strings.translate('restaurarPadrao'),
            onPressed: _restaurarPadrao,
            icon: const Icon(Icons.settings_backup_restore),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.versaoCommand, _vm.vozesCommand, widget.viewModel]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _grupo(strings.translate('texto'), [
              _linha(
                key: const ValueKey('abrirVersao'),
                icone: IconsMap.mdiIcons['book-multiple-outline'] ?? Icons.menu_book_outlined,
                titulo: strings.translate('versaoBiblia'),
                valor: _vm.versao == null ? null : '${_vm.versao!.versaCodigo} · ${_vm.versao!.versaNome}',
                bloqueado: !_vm.logado,
                onTap: _abrirVersao,
              ),
              _linha(
                icone: Icons.format_size,
                titulo: strings.translate('tamanhoFonte'),
                valor: _porcento(_vm.escalaFonte),
                onTap: () => _ajuste(strings.translate('tamanhoFonte'), _ajusteFonte),
              ),
              _linha(
                key: const ValueKey('abrirCorMarcaTexto'),
                icone: Icons.border_color_outlined,
                titulo: strings.translate('corMarcaTexto'),
                valor: strings.translate('cor_${_vm.corMarcaTexto.name}'),
                antesDoValor: _bolinha(_vm.corMarcaTexto, tamanho: 16),
                onTap: () => _escolha(
                  titulo: strings.translate('corMarcaTexto'),
                  opcoes: [for (final cor in HighlightColor.values) (cor, 'cor_${cor.name}', _bolinha(cor))],
                  atual: _vm.corMarcaTexto,
                  onEscolher: _vm.setCorMarcaTexto,
                ),
              ),
            ]),
            _grupo(strings.translate('aparencia'), [
              _linha(
                icone: Icons.palette_outlined,
                titulo: strings.translate('tema'),
                valor: strings.translate(_temas.firstWhere((t) => t.$1 == _vm.tema).$2),
                onTap: () => _escolha(
                  titulo: strings.translate('tema'),
                  opcoes: _temas,
                  atual: _vm.tema,
                  onEscolher: _vm.setTema,
                ),
              ),
              _linha(
                icone: Icons.screen_rotation_outlined,
                titulo: strings.translate('orientacaoTela'),
                valor: strings.translate(_orientacoes.firstWhere((o) => o.$1 == widget.viewModel.orientacao).$2),
                onTap: () => _escolha(
                  titulo: strings.translate('orientacaoTela'),
                  opcoes: _orientacoes,
                  atual: widget.viewModel.orientacao,
                  onEscolher: widget.viewModel.setOrientacao,
                ),
              ),
              if (_vm.brilho != null)
                _linha(
                  icone: Icons.brightness_6_outlined,
                  titulo: strings.translate('brilho'),
                  valor: _porcento(_vm.brilho!),
                  onTap: () => _ajuste(strings.translate('brilho'), _ajusteBrilho),
                ),
              SwitchListTile(
                secondary: const Icon(Icons.swap_horiz),
                title: Text(strings.translate('mostrarSetasNavegacao')),
                value: _vm.mostrarSetas,
                onChanged: _vm.setMostrarSetas,
              ),
            ]),
            if (_vm.narracaoDisponivel)
              _grupo(strings.translate('narracao'), [
                _linha(
                  key: const ValueKey('abrirVoz'),
                  icone: IconsMap.mdiIcons['account-voice'] ?? Icons.record_voice_over_outlined,
                  titulo: strings.translate('voz'),
                  valor: _resumoVoz(strings),
                  onTap: () => context.push(Routes.vozNarracao, extra: _vm),
                ),
                _linha(
                  icone: Icons.speed,
                  titulo: strings.translate('velocidadeNarracao'),
                  valor: _porcento(_vm.velocidadeNarracao / 0.5),
                  onTap: () => _ajuste(strings.translate('velocidadeNarracao'), _ajusteVelocidade),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_stories_outlined),
                  title: Text(strings.translate('narracaoContinua')),
                  value: _vm.narracaoContinua,
                  onChanged: _vm.setNarracaoContinua,
                ),
                _linha(
                  icone: Icons.play_circle_outline,
                  titulo: strings.translate('ouvirExemplo'),
                  seta: false,
                  onTap: _vm.ouvirExemplo,
                ),
              ]),
            if (_vm.anotacaoDisponivel)
              _grupo(strings.translate('anotacoes'), [
                _linha(
                  icone: Icons.label_outline,
                  titulo: strings.translate('gerenciarTags'),
                  valor: _vm.tags.isEmpty ? null : '${_vm.tags.length}',
                  onTap: () => DialogSheet.show<void>(
                    context,
                    titulo: strings.translate('gerenciarTags'),
                    conteudo: TagsLeituraSheet(viewModel: _vm),
                  ),
                ),
              ]),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                key: const ValueKey('restaurarPadrao'),
                onPressed: _restaurarPadrao,
                icon: const Icon(Icons.settings_backup_restore, size: 18),
                label: Text(strings.translate('restaurarPadrao')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Título discreto e um card com os [itens] separados por linhas finas.
  Widget _grupo(String titulo, List<Widget> itens) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(titulo, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary)),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, item) in itens.indexed) ...[
                if (i > 0) Divider(height: 1, indent: 56, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                item,
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Versão da Bíblia: com login, a tela de versões; sem login (restrito), o sheet que leva ao login. O login é
  /// uma tela de fora da leitura: brilho e orientação voltam aos do sistema enquanto ele está aberto.
  Future<void> _abrirVersao() async {
    if (_vm.logado) {
      await context.push(Routes.versaoBiblia, extra: _vm);
      return;
    }
    final strings = AppLocalizations.of(context);
    final entrar = await LoginNecessarioSheet.perguntar(
      context,
      titulo: strings.translate('versaoBiblia'),
      mensagem: 'selecaoVersaoRestritaLogin',
    );
    if (!entrar || !mounted) return;
    await _vm.sairDaLeitura();
    if (!mounted) return;
    await context.push(Routes.login);
    if (mounted) await _vm.entrarNaLeitura();
  }

  /// Linha com ícone, título, o [valor] atual à direita (discreto) e a seta (ou um cadeado se [bloqueado]).
  Widget _linha({
    Key? key,
    required IconData icone,
    required String titulo,
    String? valor,
    bool seta = true,
    bool bloqueado = false,
    Widget? antesDoValor,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: key,
      leading: Icon(icone),
      title: Text(titulo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (antesDoValor != null) Padding(padding: const EdgeInsets.only(right: 8), child: antesDoValor),
          if (valor != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
              child: Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          if (bloqueado)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.lock_outline, size: 20, color: scheme.onSurfaceVariant),
            )
          else if (seta)
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }

  String? _resumoVoz(AppLocalizations strings) {
    if (_vm.vozesCommand.running) return '…';
    final voz = _vm.vozNarracao;
    if (voz == null) return strings.translate('nenhumaVoz');
    final partes = BibliaLeituraUseCase.partesLocale(voz.locale);
    return '${NomesVoz.voz(strings, voz, _vm.vozes)} · ${NomesVoz.bandeira(partes.pais)}'.trim();
  }

  /// Sheet de baixo com um ajuste que acompanha a leitura ao vivo.
  Future<void> _ajuste(String titulo, Widget Function() conteudo) => DialogSheet.show<void>(
    context,
    titulo: titulo,
    conteudo: ListenableBuilder(listenable: _vm, builder: (context, _) => conteudo()),
  );

  /// Sheet de baixo com uma lista de opções; tocar escolhe e fecha.
  Future<void> _escolha<T>({
    required String titulo,
    required List<(T, String, Widget)> opcoes,
    required T atual,
    required ValueChanged<T> onEscolher,
  }) {
    final strings = AppLocalizations.of(context);
    return DialogSheet.show<void>(
      context,
      titulo: titulo,
      conteudo: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (valor, chave, icone) in opcoes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: icone,
                title: Text(strings.translate(chave)),
                selected: valor == atual,
                trailing: valor == atual ? const Icon(Icons.check) : null,
                onTap: () {
                  onEscolher(valor);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _ajusteFonte() {
    final textTheme = Theme.of(context).textTheme;
    final base = textTheme.bodyLarge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            BibliaLeituraUseCase.exemploNarracao,
            key: const ValueKey('previaFonte'),
            style: base?.copyWith(height: 1.5, fontSize: (base.fontSize ?? 16) * _vm.escalaFonte),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('A', style: textTheme.bodySmall),
            Expanded(
              child: Slider(
                key: const ValueKey('tamanhoFonte'),
                value: _vm.escalaFonte,
                min: BibliaLeituraUseCase.escalaFonteMinima,
                max: BibliaLeituraUseCase.escalaFonteMaxima,
                divisions: 8,
                label: _porcento(_vm.escalaFonte),
                onChanged: _vm.setEscalaFonte,
              ),
            ),
            Text('A', style: textTheme.titleLarge),
          ],
        ),
      ],
    );
  }

  Widget _ajusteBrilho() => Row(
    children: [
      const Icon(Icons.brightness_low, size: 20),
      Expanded(
        child: Slider(key: const ValueKey('brilho'), value: _vm.brilho ?? 0.5, onChanged: _vm.setBrilho),
      ),
      const Icon(Icons.brightness_high, size: 24),
    ],
  );

  Widget _ajusteVelocidade() {
    final strings = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                label: _porcento(_vm.velocidadeNarracao / 0.5),
                onChanged: _vm.setVelocidadeNarracao,
              ),
            ),
            Tooltip(message: strings.translate('maisRapido'), child: const Icon(Icons.fast_forward_outlined, size: 22)),
          ],
        ),
        Align(
          child: TextButton.icon(
            onPressed: _vm.ouvirExemplo,
            icon: const Icon(Icons.play_arrow),
            label: Text(strings.translate('ouvirExemplo')),
          ),
        ),
      ],
    );
  }

  /// Pergunta e volta tudo ao padrão (a versão, as tags e as anotações ficam).
  Future<void> _restaurarPadrao() async {
    final strings = AppLocalizations.of(context);
    final confirmou = await DialogSheet.show<bool>(
      context,
      titulo: strings.translate('restaurarPadrao'),
      conteudo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.translate('restaurarPadraoPergunta'), style: Theme.of(context).textTheme.bodyLarge),
          Builder(
            builder: (sheetContext) => DialogSheet.acoes([
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(strings.translate('cancelar')),
              ),
              FilledButton(
                key: const ValueKey('confirmarRestaurarPadrao'),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: Text(strings.translate('restaurar')),
              ),
            ]),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    widget.viewModel.restaurarPadrao();
    await _vm.restaurarPadrao();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.translate('padraoRestaurado'))));
  }
}
