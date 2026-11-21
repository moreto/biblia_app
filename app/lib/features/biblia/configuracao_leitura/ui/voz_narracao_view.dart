import 'package:app/config/icons_map.dart';
import 'package:app/config/narracao_voz.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../biblia_leitura/ui/biblia_leitura_viewmodel.dart';
import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';
import 'nomes_voz.dart';

/// Escolha da voz da narração (`/voz-narracao`), aberta pelas Configurações de leitura.
///
/// Primeiro o idioma, depois o país (com a bandeira) e então a voz, com nome amigável ([NomesVoz.voz]) e a
/// qualidade. O ▶ de cada voz toca um exemplo sem escolher; tocar na voz a escolhe (e toca o exemplo). Começa no
/// idioma e no país da voz atual.
class VozNarracaoView extends StatefulWidget {
  const VozNarracaoView({super.key, required this.leitura});

  final BibliaLeituraViewmodel leitura;

  @override
  State<VozNarracaoView> createState() => _VozNarracaoViewState();
}

class _VozNarracaoViewState extends State<VozNarracaoView> {
  BibliaLeituraViewmodel get _vm => widget.leitura;

  String? _idioma;
  String? _pais;

  @override
  void initState() {
    super.initState();
    if (_vm.vozesCommand.result == null) _vm.vozesCommand.execute();
  }

  @override
  void dispose() {
    _vm.pararNarracao();
    super.dispose();
  }

  /// Idioma e país mostrados: os escolhidos aqui ou, até lá, os da voz atual (ou da primeira).
  ({String idioma, String? pais})? _filtro(List<VozNarracao> vozes) {
    final base = _vm.vozNarracao ?? vozes.firstOrNull;
    if (base == null) return null;
    final daVoz = BibliaLeituraUseCase.partesLocale(base.locale);
    final idioma = _idioma ?? daVoz.idioma;
    final paises = BibliaLeituraUseCase.paisesDasVozes(vozes, idioma);
    final pais = _idioma == null ? daVoz.pais : _pais;
    return (idioma: idioma, pais: paises.contains(pais) ? pais : paises.firstOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.translate('vozNarracao'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.vozesCommand]),
        builder: (context, _) {
          if (_vm.vozesCommand.running) return const Center(child: CircularProgressIndicator());
          final vozes = _vm.vozes;
          final filtro = _filtro(vozes);
          if (filtro == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(strings.translate('nenhumaVoz'), textAlign: TextAlign.center),
              ),
            );
          }
          final idiomas = BibliaLeituraUseCase.idiomasDasVozes(vozes);
          final paises = BibliaLeituraUseCase.paisesDasVozes(vozes, filtro.idioma);
          final daqui = BibliaLeituraUseCase.vozesDe(vozes, filtro.idioma, filtro.pais);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('idioma_${filtro.idioma}'),
                initialValue: filtro.idioma,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: strings.translate('idioma'),
                  prefixIcon: const Icon(Icons.translate),
                  border: const OutlineInputBorder(),
                ),
                items: [for (final i in idiomas) DropdownMenuItem(value: i, child: Text(NomesVoz.idioma(strings, i)))],
                onChanged: (i) => setState(() {
                  _idioma = i;
                  _pais = null;
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: ValueKey('pais_${filtro.idioma}_${filtro.pais}'),
                initialValue: filtro.pais,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: strings.translate('pais'),
                  prefixIcon: const Icon(Icons.public),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final p in paises)
                    DropdownMenuItem(
                      value: p,
                      child: Text('${NomesVoz.bandeira(p)}  ${NomesVoz.pais(strings, p)}'.trim()),
                    ),
                ],
                onChanged: (p) => setState(() {
                  _idioma = filtro.idioma;
                  _pais = p;
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  strings.translate('vozes'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, voz) in daqui.indexed) ...[
                      if (i > 0) const Divider(height: 1, indent: 72),
                      _voz(strings, voz, vozes),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _voz(AppLocalizations strings, VozNarracao voz, List<VozNarracao> vozes) {
    final scheme = Theme.of(context).colorScheme;
    final escolhida = _vm.vozNarracao?.nome == voz.nome;
    return ListTile(
      key: ValueKey('voz_${voz.nome}'),
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      leading: CircleAvatar(
        backgroundColor: escolhida ? scheme.primary : scheme.secondaryContainer,
        foregroundColor: escolhida ? scheme.onPrimary : scheme.onSecondaryContainer,
        child: Icon(IconsMap.mdiIcons['account-voice'] ?? Icons.record_voice_over),
      ),
      title: Text(NomesVoz.voz(strings, voz, vozes)),
      subtitle: Text(NomesVoz.detalhes(strings, voz)),
      selected: escolhida,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (escolhida) Icon(Icons.check_circle, color: scheme.primary),
          IconButton(
            tooltip: strings.translate('ouvirVoz'),
            onPressed: () => _vm.ouvirVoz(voz),
            icon: const Icon(Icons.play_circle_outline),
          ),
        ],
      ),
      onTap: () => _vm.setVozNarracao(voz),
    );
  }
}
