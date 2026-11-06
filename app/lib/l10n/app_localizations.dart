import 'package:app/l10n/traducao_repository_impl.dart';
import 'package:commons/result.dart';
import 'package:flutter/material.dart';

import '../data/model/traducao_model.dart';
import 'traducao_repository.dart';

class AppLocalizations {
  AppLocalizations({required Locale locale, required List<TraducaoModel> translations})
    : this._(locale: locale, translations: translations);

  AppLocalizations._({required this.locale, required this._translations});

  final Locale locale;
  final List<TraducaoModel> _translations;

  static const supportedLocales = [Locale('pt', 'BR'), Locale('es', 'ES'), Locale('en', 'US')];
  static final LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate(TraducaoRepositoryImpl());

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String translate(String key) {
    final normalizedKey = _normalize(key);
    TraducaoModel? translation;

    for (final item in _translations) {
      if (_normalize(item.tradChave) == normalizedKey || _normalize(item.tradPtBr) == normalizedKey) {
        translation = item;
        break;
      }
    }

    final remoteValue = switch (locale.languageCode) {
      'es' => translation?.tradEsEs,
      'en' => translation?.tradEnUs,
      _ => translation?.tradPtBr,
    };
    if (remoteValue != null && remoteValue.trim().isNotEmpty) return remoteValue;
    return key;
  }

  static String _normalize(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate(this._repository);

  final TraducaoRepository _repository;

  @override
  bool isSupported(Locale locale) => const {'pt', 'es', 'en'}.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final result = await _repository.get();
    final translations = switch (result) {
      Ok<List<TraducaoModel>>(value: final value) => value,
      Error<List<TraducaoModel>>() => const <TraducaoModel>[],
    };
    return AppLocalizations(locale: locale, translations: translations);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
