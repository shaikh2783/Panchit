import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationController extends GetxController {
  static LocalizationController get instance => Get.find();
  static const String _keyLanguage = 'app_language';
  static const Locale fallbackLocale = Locale('en', 'US');

  static const Map<String, Locale> _supportedLocales = {
    // English & Arabic
    'en_US': Locale('en', 'US'),
    'ar_SA': Locale('ar', 'SA'),

    // Indian Languages
    'bn_IN': Locale('bn', 'IN'),
    'gu_IN': Locale('gu', 'IN'),
    'hi_IN': Locale('hi', 'IN'),
    'kn_IN': Locale('kn', 'IN'),
    'ml_IN': Locale('ml', 'IN'),
    'mr_IN': Locale('mr', 'IN'),
    'or_IN': Locale('or', 'IN'),
    'ta_IN': Locale('ta', 'IN'),
    'te_IN': Locale('te', 'IN'),

    // Urdu
    'ur_PK': Locale('ur', 'PK'),

    // European
    'fr_FR': Locale('fr', 'FR'),
    'es_ES': Locale('es', 'ES'),
    'pt_PT': Locale('pt', 'PT'),
    'pt_BR': Locale('pt', 'BR'),
    'de_DE': Locale('de', 'DE'),
    'tr_TR': Locale('tr', 'TR'),
    'nl_NL': Locale('nl', 'NL'),
    'it_IT': Locale('it', 'IT'),
    'ru_RU': Locale('ru', 'RU'),
    'ro_RO': Locale('ro', 'RO'),
    'el_GR': Locale('el', 'GR'),
  };


  static const Map<String, String> _languageAliases = {
    'en': 'en_US',
    'ar': 'ar_SA',
    'fr': 'fr_FR',
    'es': 'es_ES',
    'pt': 'pt_PT',
    'pt_br': 'pt_BR',
    'de': 'de_DE',
    'tr': 'tr_TR',
    'nl': 'nl_NL',
    'it': 'it_IT',
    'ru': 'ru_RU',
    'ro': 'ro_RO',
    'el': 'el_GR',
    'gr': 'el_GR',
  };

  final List<LanguageOption> languageOptions = const [
    LanguageOption(
      code: 'en_US',
      locale: Locale('en', 'US'),
      flag: '🇺🇸',
      nameKey: 'english',
      nativeName: 'English',
      subtitle: 'English - United States',
    ),
    LanguageOption(
      code: 'ar_SA',
      locale: Locale('ar', 'SA'),
      flag: '🇸🇦',
      nameKey: 'arabic',
      nativeName: 'العربية',
      subtitle: 'العربية - Saudi Arabia',
    ),
    LanguageOption(
      code: 'bn_IN',
      locale: Locale('bn', 'IN'),
      flag: '🇮🇳',
      nameKey: 'bengali',
      nativeName: 'বাংলা',
      subtitle: 'বাংলা - India',
    ),
    LanguageOption(
      code: 'gu_IN',
      locale: Locale('gu', 'IN'),
      flag: '🇮🇳',
      nameKey: 'gujarati',
      nativeName: 'ગુજરાતી',
      subtitle: 'ગુજરાતી - India',
    ),
    LanguageOption(
      code: 'hi_IN',
      locale: Locale('hi', 'IN'),
      flag: '🇮🇳',
      nameKey: 'hindi',
      nativeName: 'हिन्दी',
      subtitle: 'हिन्दी - India',
    ),
    LanguageOption(
      code: 'kn_IN',
      locale: Locale('kn', 'IN'),
      flag: '🇮🇳',
      nameKey: 'kannada',
      nativeName: 'ಕನ್ನಡ',
      subtitle: 'ಕನ್ನಡ - India',
    ),
    LanguageOption(
      code: 'ml_IN',
      locale: Locale('ml', 'IN'),
      flag: '🇮🇳',
      nameKey: 'malayalam',
      nativeName: 'മലയാളം',
      subtitle: 'മലയാളം - India',
    ),
    LanguageOption(
      code: 'mr_IN',
      locale: Locale('mr', 'IN'),
      flag: '🇮🇳',
      nameKey: 'marathi',
      nativeName: 'मराठी',
      subtitle: 'मराठी - India',
    ),
    LanguageOption(
      code: 'or_IN',
      locale: Locale('or', 'IN'),
      flag: '🇮🇳',
      nameKey: 'odia',
      nativeName: 'ଓଡ଼ିଆ',
      subtitle: 'ଓଡ଼ିଆ - India',
    ),
    LanguageOption(
      code: 'ta_IN',
      locale: Locale('ta', 'IN'),
      flag: '🇮🇳',
      nameKey: 'tamil',
      nativeName: 'தமிழ்',
      subtitle: 'தமிழ் - India',
    ),
    LanguageOption(
      code: 'te_IN',
      locale: Locale('te', 'IN'),
      flag: '🇮🇳',
      nameKey: 'telugu',
      nativeName: 'తెలుగు',
      subtitle: 'తెలుగు - India',
    ),

    // ---------------- Urdu ----------------

    LanguageOption(
      code: 'ur_PK',
      locale: Locale('ur', 'PK'),
      flag: '🇵🇰',
      nameKey: 'urdu',
      nativeName: 'اردو',
      subtitle: 'اردو - Pakistan',
    ),

    LanguageOption(
      code: 'fr_FR',
      locale: Locale('fr', 'FR'),
      flag: '🇫🇷',
      nameKey: 'french',
      nativeName: 'Français',
      subtitle: 'Français - France',
    ),
    LanguageOption(
      code: 'es_ES',
      locale: Locale('es', 'ES'),
      flag: '🇪🇸',
      nameKey: 'spanish',
      nativeName: 'Español',
      subtitle: 'Español - España',
    ),
    LanguageOption(
      code: 'pt_PT',
      locale: Locale('pt', 'PT'),
      flag: '🇵🇹',
      nameKey: 'portuguese',
      nativeName: 'Português',
      subtitle: 'Português - Portugal',
    ),
    LanguageOption(
      code: 'pt_BR',
      locale: Locale('pt', 'BR'),
      flag: '🇧🇷',
      nameKey: 'portuguese_br',
      nativeName: 'Português (Brasil)',
      subtitle: 'Português - Brazil',
    ),
    LanguageOption(
      code: 'de_DE',
      locale: Locale('de', 'DE'),
      flag: '🇩🇪',
      nameKey: 'german',
      nativeName: 'Deutsch',
      subtitle: 'Deutsch - Germany',
    ),
    LanguageOption(
      code: 'tr_TR',
      locale: Locale('tr', 'TR'),
      flag: '🇹🇷',
      nameKey: 'turkish',
      nativeName: 'Türkçe',
      subtitle: 'Türkçe - Turkey',
    ),
    LanguageOption(
      code: 'nl_NL',
      locale: Locale('nl', 'NL'),
      flag: '🇳🇱',
      nameKey: 'dutch',
      nativeName: 'Nederlands',
      subtitle: 'Nederlands - Netherlands',
    ),
    LanguageOption(
      code: 'it_IT',
      locale: Locale('it', 'IT'),
      flag: '🇮🇹',
      nameKey: 'italian',
      nativeName: 'Italiano',
      subtitle: 'Italiano - Italy',
    ),
    LanguageOption(
      code: 'ru_RU',
      locale: Locale('ru', 'RU'),
      flag: '🇷🇺',
      nameKey: 'russian',
      nativeName: 'Русский',
      subtitle: 'Русский - Russia',
    ),
    LanguageOption(
      code: 'ro_RO',
      locale: Locale('ro', 'RO'),
      flag: '🇷🇴',
      nameKey: 'romanian',
      nativeName: 'Română',
      subtitle: 'Română - Romania',
    ),
    LanguageOption(
      code: 'el_GR',
      locale: Locale('el', 'GR'),
      flag: '🇬🇷',
      nameKey: 'greek',
      nativeName: 'Ελληνικά',
      subtitle: 'Ελληνικά - Greece',
    ),
  ];


  final _locale = fallbackLocale.obs; // Default to English on first launch

  Locale get locale => _locale.value;
  Locale get currentLocale => _locale.value;

  List<Locale> get supportedLocales => _supportedLocales.values.toList();

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
  }

  void changeLocale(String languageCode) {
    final normalizedCode = _normalizeCode(languageCode);
    final locale = _supportedLocales[normalizedCode] ?? fallbackLocale;
    _locale.value = locale;
    Get.updateLocale(locale);

    _saveLocaleToPrefs(normalizedCode);
  }

  void toggleLanguage() {
    final index = languageOptions.indexWhere((option) => option.locale == _locale.value);
    final nextIndex = (index + 1) % languageOptions.length;
    changeLocale(languageOptions[nextIndex].code);
  }

  void _saveLocaleToPrefs(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, languageCode);
    } catch (e) {
    }
  }

  void _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_keyLanguage);

      final normalizedCode =
          savedLanguage != null && savedLanguage.isNotEmpty ? _normalizeCode(savedLanguage) : null;
      final locale = normalizedCode != null
          ? (_supportedLocales[normalizedCode] ?? fallbackLocale)
          : fallbackLocale;
      _locale.value = locale;
      Get.updateLocale(locale);
    } catch (e) {
    }
  }

  bool get isArabic => _locale.value.languageCode == 'ar';
  bool get isEnglish => _locale.value.languageCode == 'en';
  bool get isRTL => _rtlLanguageCodes.contains(_locale.value.languageCode);

  String _normalizeCode(String code) {
    final lower = code.trim().toLowerCase();
    if (_languageAliases.containsKey(lower)) {
      return _languageAliases[lower]!;
    }

    final direct = _supportedLocales.keys.firstWhere(
      (supportedCode) => supportedCode.toLowerCase() == lower,
      orElse: () => 'en_US',
    );

    return direct;
  }
}

// Languages that should render Right-to-Left layouts.
const Set<String> _rtlLanguageCodes = {'ar', 'fa', 'ur', 'he'};

class LanguageOption {
  final String code;
  final Locale locale;
  final String flag;
  final String nameKey;
  final String nativeName;
  final String subtitle;

  const LanguageOption({
    required this.code,
    required this.locale,
    required this.flag,
    required this.nameKey,
    required this.nativeName,
    required this.subtitle,
  });
}
