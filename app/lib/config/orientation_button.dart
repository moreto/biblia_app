import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Botão para as `actions` das AppBars que alterna a orientação da tela
/// entre vertical (retrato) e horizontal (paisagem).
///
/// Usa a orientação atual de [MediaQuery] para decidir a próxima e fixa a
/// orientação escolhida com [SystemChrome.setPreferredOrientations]. O ícone
/// e o tooltip indicam a orientação que será aplicada ao tocar. Em web e
/// desktop o sistema ignora a preferência.
class OrientationButton extends StatelessWidget {
  const OrientationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    return IconButton(
      tooltip: strings.translate(isPortrait ? 'telaHorizontal' : 'telaVertical'),
      icon: Icon(isPortrait ? Icons.stay_current_landscape : Icons.stay_current_portrait),
      onPressed: () => SystemChrome.setPreferredOrientations(
        isPortrait
            ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
            : const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      ),
    );
  }
}
