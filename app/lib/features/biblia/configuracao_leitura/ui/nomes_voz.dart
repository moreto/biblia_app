import 'package:app/config/narracao_voz.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../biblia_leitura/use_case/biblia_leitura_usecase.dart';

/// Nomes amigáveis para as vozes da narração: idioma, país (com a bandeira) e "Voz N".
abstract final class NomesVoz {
  /// Tradução de [chave] ou, se não houver (a tradução devolve a própria chave), [padrao].
  static String _ou(AppLocalizations strings, String chave, String padrao) {
    final traduzido = strings.translate(chave);
    return traduzido == chave ? padrao : traduzido;
  }

  /// Nome do idioma (chave `idioma_<código>`, ex.: `idioma_pt`); sem tradução, o código em maiúsculas.
  static String idioma(AppLocalizations strings, String codigo) => _ou(strings, 'idioma_$codigo', codigo.toUpperCase());

  /// Nome do país (chave `pais_<código>`, ex.: `pais_BR`); sem país, "Padrão"; sem tradução, o código.
  static String pais(AppLocalizations strings, String? codigo) =>
      codigo == null ? strings.translate('paisPadrao') : _ou(strings, 'pais_$codigo', codigo);

  /// Bandeira do país (emoji a partir das duas letras do código); vazia sem país ou com região numérica.
  static String bandeira(String? codigo) {
    if (codigo == null || !RegExp(r'^[A-Z]{2}$').hasMatch(codigo)) return '';
    return String.fromCharCodes(codigo.codeUnits.map((c) => 0x1F1E6 + c - 0x41));
  }

  /// "Português (Brasil)".
  static String idiomaEPais(AppLocalizations strings, String locale) {
    final partes = BibliaLeituraUseCase.partesLocale(locale);
    final nome = idioma(strings, partes.idioma);
    return partes.pais == null ? nome : '$nome (${pais(strings, partes.pais)})';
  }

  /// Nome amigável da [voz] entre as [vozes]: o nome dela quando é de gente, senão "Voz N".
  static String voz(AppLocalizations strings, VozNarracao voz, List<VozNarracao> vozes) {
    final amigavel = BibliaLeituraUseCase.nomeAmigavel(voz, vozes);
    return amigavel.nome ?? '${strings.translate('voz')} ${amigavel.numero}';
  }

  /// Qualidade e, se for o caso, "online": "Alta qualidade · Online".
  static String detalhes(AppLocalizations strings, VozNarracao voz) => [
    strings.translate(BibliaLeituraUseCase.rotuloQualidade(voz)),
    if (voz.online) strings.translate('vozOnline'),
  ].join(' · ');
}
