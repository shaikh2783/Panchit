import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  final String code;        // en_US
  final String language;    // en
  final String country;     // US
  final String name;        // English
  final String native;      // English / العربية / বাংলা
  final String flag;
  final bool isRTL;

  const AppLanguage({
    required this.code,
    required this.language,
    required this.country,
    required this.name,
    required this.native,
    required this.flag,
    this.isRTL = false,
  });

  Locale get locale => Locale(language, country);
}

class LocalizationController extends GetxController {
  static LocalizationController get instance => Get.find();

  static const String _keyLanguage = 'app_language';

  final Rx<Locale> _locale = const Locale('en', 'US').obs;

  Locale get locale => _locale.value;
  Locale get currentLocale => _locale.value;

  // 🔥 SINGLE SOURCE OF TRUTH
  final List<AppLanguage> languages = const [
    AppLanguage(
      code: 'en_US',
      language: 'en',
      country: 'US',
      name: 'English',
      native: 'English',
      flag: '🇺🇸',
    ),
    AppLanguage(
      code: 'ar_SA',
      language: 'ar',
      country: 'SA',
      name: 'Arabic',
      native: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
    AppLanguage(
      code: 'bn_in',
      language: 'bn',
      country: 'IN',
      name: 'Bengali',
      native: 'বাংলা',
      flag: '🇮🇳',
    ),
    AppLanguage(
      code: 'hi_in',
      language: 'hi',
      country: 'IN',
      name: 'Hindi',
      native: 'हिन्दी',
      flag: '🇮🇳',
    ),
    AppLanguage(
      code: 'ta_in',
      language: 'ta',
      country: 'IN',
      name: 'Tamil',
      native: 'தமிழ்',
      flag: '🇮🇳',
    ),
    AppLanguage(
      code: 'te_in',
      language: 'te',
      country: 'IN',
      name: 'Telugu',
      native: 'తెలుగు',
      flag: '🇮🇳',
    ),
    AppLanguage(
      code: 'ur_pk',
      language: 'ur',
      country: 'PK',
      name: 'Urdu',
      native: 'اردو',
      flag: '🇵🇰',
      isRTL: true,
    ),
    // ➕ add the rest here ONCE
  ];

  @override
  void onInit() {
    super.onInit();
    _restoreLocale();
  }

  // ----------------- ACTIONS -----------------

  void changeLanguage(AppLanguage lang) async {
    _locale.value = lang.locale;
    Get.updateLocale(lang.locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang.code);

    update();
  }

  void changeLocaleByCode(String code) {
    final lang = languages.firstWhereOrNull((l) => l.code == code);
    if (lang != null) {
      changeLanguage(lang);
    }
  }

  void toggleLanguage() {
    // keeps your old behavior
    final next = isArabic
        ? languages.firstWhere((l) => l.language == 'en')
        : languages.firstWhere((l) => l.language == 'ar');
    changeLanguage(next);
  }

  // ----------------- HELPERS -----------------

  bool isSelected(AppLanguage lang) =>
      _locale.value.languageCode == lang.language &&
          _locale.value.countryCode == lang.country;

  bool get isArabic => _locale.value.languageCode == 'ar';
  bool get isEnglish => _locale.value.languageCode == 'en';

  bool get isRTL =>
      languages.firstWhereOrNull(
            (l) =>
        l.language == _locale.value.languageCode &&
            l.country == _locale.value.countryCode,
      )?.isRTL ??
          false;

  List<Locale> get supportedLocales =>
      languages.map((l) => l.locale).toList();

  // ----------------- PERSISTENCE -----------------

  Future<void> _restoreLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLanguage);

    if (code == null) return;

    final lang = languages.firstWhereOrNull((l) => l.code == code);
    if (lang != null) {
      _locale.value = lang.locale;
      Get.updateLocale(lang.locale);
      update();
    }
  }
}
