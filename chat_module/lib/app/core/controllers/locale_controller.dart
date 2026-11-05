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

  // Kept in lockstep with the host app's supported languages
  // (lib/core/localization/translations/ and localization_controller.dart).
  static const List<AppLanguage> supportedLanguages = <AppLanguage>[
    AppLanguage(code: 'en', countryCode: 'US', label: 'English', apiCode: 'en_us'),
    AppLanguage(code: 'ar', countryCode: 'SA', label: 'العربية', apiCode: 'ar_sa'),
    AppLanguage(code: 'bn', countryCode: 'IN', label: 'বাংলা', apiCode: 'bn_in'),
    AppLanguage(code: 'gu', countryCode: 'IN', label: 'ગુજરાતી', apiCode: 'gu_in'),
    AppLanguage(code: 'hi', countryCode: 'IN', label: 'हिन्दी', apiCode: 'hi_in'),
    AppLanguage(code: 'kn', countryCode: 'IN', label: 'ಕನ್ನಡ', apiCode: 'kn_in'),
    AppLanguage(code: 'ml', countryCode: 'IN', label: 'മലയാളം', apiCode: 'ml_in'),
    AppLanguage(code: 'mr', countryCode: 'IN', label: 'मराठी', apiCode: 'mr_in'),
    AppLanguage(code: 'or', countryCode: 'IN', label: 'ଓଡ଼ିଆ', apiCode: 'or_in'),
    AppLanguage(code: 'ta', countryCode: 'IN', label: 'தமிழ்', apiCode: 'ta_in'),
    AppLanguage(code: 'te', countryCode: 'IN', label: 'తెలుగు', apiCode: 'te_in'),
    AppLanguage(code: 'ur', countryCode: 'PK', label: 'اردو', apiCode: 'ur_pk'),
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

    // No explicit choice made from inside chat yet: follow whatever
    // language the host app (localization_controller.dart) is already
    // showing instead of guessing from the device locale.
    final hostSaved = _preferences.getHostLanguage()?.trim() ?? '';
    if (hostSaved.isNotEmpty) {
      final hostLocale = _parseSavedLocale(hostSaved);
      if (hostLocale != null) {
        _currentLocale = hostLocale;
        Get.updateLocale(hostLocale);
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
    final stored = _localeToStorageValue(resolved);
    await _preferences.setLocaleValue(stored);
    // Keep the host app's own language switch in sync so the choice made
    // here isn't reverted the next time the app launches normally.
    await _preferences.setHostLanguage(stored);
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
    return supportedLanguages.first.locale;
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
