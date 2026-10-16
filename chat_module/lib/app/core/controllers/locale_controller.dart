import 'dart:ui';

import 'package:get/get.dart';

import '../storage/app_preferences.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.label,
    required this.apiCode,
    this.countryCode,
  });

  final String code;
  final String label;
  final String apiCode;
  final String? countryCode;

  Locale get locale =>
      countryCode == null ? Locale(code) : Locale(code, countryCode);

  String get storageKey => countryCode == null ? code : '${code}_$countryCode';
}

class ChatLocaleController extends GetxController {
  ChatLocaleController(this._preferences);

  final ChatAppPreferences _preferences;

  static const List<AppLanguage> supportedLanguages = <AppLanguage>[
    AppLanguage(code: 'en', label: 'English', apiCode: 'en_us'),
    AppLanguage(code: 'ar', label: 'العربية', apiCode: 'ar_sa'),
    AppLanguage(code: 'fr', label: 'Français', apiCode: 'fr_fr'),
    AppLanguage(code: 'es', label: 'Español', apiCode: 'es_es'),
    AppLanguage(code: 'pt', label: 'Português', apiCode: 'pt_pt'),
    AppLanguage(code: 'de', label: 'Deutsch', apiCode: 'de_de'),
    AppLanguage(code: 'tr', label: 'Türkçe', apiCode: 'tr_tr'),
    AppLanguage(code: 'nl', label: 'Nederlands', apiCode: 'nl_nl'),
    AppLanguage(code: 'it', label: 'Italiano', apiCode: 'it_it'),
    AppLanguage(code: 'ru', label: 'Русский', apiCode: 'ru_ru'),
    AppLanguage(code: 'ro', label: 'Română', apiCode: 'ro_ro'),
    AppLanguage(code: 'uk', label: 'Українська', apiCode: 'uk_ua'),
    AppLanguage(
      code: 'pt',
      countryCode: 'BR',
      label: 'Português (Brasil)',
      apiCode: 'pt_br',
    ),
    AppLanguage(code: 'el', label: 'Ελληνικά', apiCode: 'el_gr'),
  ];

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  List<Locale> get supportedLocales =>
      supportedLanguages.map((language) => language.locale).toList();

  AppLanguage get currentLanguage {
    for (final language in supportedLanguages) {
      if (_matches(language.locale, _currentLocale)) {
        return language;
      }
    }
    return supportedLanguages.first;
  }

  Future<void> loadSavedLocale() async {
    final saved = _preferences.getLocaleValue()?.trim() ?? '';
    if (saved.isNotEmpty) {
      final locale = _parseSavedLocale(saved);
      if (locale != null) {
        _currentLocale = locale;
        Get.updateLocale(locale);
        update();
        return;
      }
    }

    final deviceLocale = Get.deviceLocale ?? PlatformDispatcher.instance.locale;
    final fallback = _resolveSupportedLocale(deviceLocale);
    _currentLocale = fallback;
    Get.updateLocale(fallback);
    update();
  }

  Future<void> changeLocale(Locale locale) async {
    final resolved = _resolveSupportedLocale(locale);
    if (_matches(resolved, _currentLocale)) {
      return;
    }

    _currentLocale = resolved;
    await _preferences.setLocaleValue(_localeToStorageValue(resolved));
    await Get.updateLocale(resolved);
    update();
  }

  Future<void> applyIncomingLocaleValue(String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    final locale = _parseSavedLocale(normalized);
    if (locale == null) {
      return;
    }

    if (_matches(locale, _currentLocale)) {
      await _preferences.setLocaleValue(_localeToStorageValue(locale));
      return;
    }

    _currentLocale = locale;
    await _preferences.setLocaleValue(_localeToStorageValue(locale));
    await Get.updateLocale(locale);
    update();
  }

  Locale _resolveSupportedLocale(Locale locale) {
    for (final language in supportedLanguages) {
      if (_matches(language.locale, locale)) {
        return language.locale;
      }
    }
    for (final language in supportedLanguages) {
      if (language.code == locale.languageCode) {
        return language.locale;
      }
    }
    return const Locale('en');
  }

  Locale? _parseSavedLocale(String value) {
    final parts = value.split('_');
    if (parts.isEmpty || parts.first.trim().isEmpty) {
      return null;
    }
    final locale = parts.length > 1
        ? Locale(parts.first, parts[1])
        : Locale(parts.first);
    return _resolveSupportedLocale(locale);
  }

  String _localeToStorageValue(Locale locale) {
    final countryCode = locale.countryCode?.trim() ?? '';
    return countryCode.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_$countryCode';
  }

  bool _matches(Locale a, Locale b) {
    return a.languageCode == b.languageCode &&
        (a.countryCode ?? '') == (b.countryCode ?? '');
  }
}
