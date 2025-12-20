import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snginepro/core/localization/AppLanguage.dart';
class LocalizationController extends GetxController {
  static LocalizationController get instance => Get.find();
  static const String _keyLanguage = 'app_language';
  final _locale = const Locale('en', 'US').obs; // Default to English on first launch
  Locale get locale => _locale.value;
  Locale get currentLocale => _locale.value;
  final List<Locale> supportedLocales = const [
    Locale('en', 'US'), // English - Default
    Locale('ar', 'SA'), // Arabic
  ];

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
      code: 'bn_IN',
      language: 'bn',
      country: 'IN',
      name: 'Bengali',
      native: 'বাংলা',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'gu_IN',
      language: 'gu',
      country: 'IN',
      name: 'Gujarati',
      native: 'ગુજરાતી',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'hi_IN',
      language: 'hi',
      country: 'IN',
      name: 'Hindi',
      native: 'हिन्दी',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'kn_IN',
      language: 'kn',
      country: 'IN',
      name: 'Kannada',
      native: 'ಕನ್ನಡ',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'ml_IN',
      language: 'ml',
      country: 'IN',
      name: 'Malayalam',
      native: 'മലയാളം',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'mr_IN',
      language: 'mr',
      country: 'IN',
      name: 'Marathi',
      native: 'मराठी',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'or_IN',
      language: 'or',
      country: 'IN',
      name: 'Odia',
      native: 'ଓଡ଼ିଆ',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'ta_IN',
      language: 'ta',
      country: 'IN',
      name: 'Tamil',
      native: 'தமிழ்',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'te_IN',
      language: 'te',
      country: 'IN',
      name: 'Telugu',
      native: 'తెలుగు',
      flag: '🇮🇳',
    ),

    AppLanguage(
      code: 'ur_PK',
      language: 'ur',
      country: 'PK',
      name: 'Urdu',
      native: 'اردو',
      flag: '🇵🇰',
      isRTL: true,
    ),
  ];


  bool isSelected(AppLanguage lang) {
    return _locale.value.languageCode == lang.language &&
        _locale.value.countryCode == lang.country;
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
  }
  void changeLanguage(AppLanguage lang) {
    final locale = Locale(lang.language, lang.country);
    _locale.value = locale;
    Get.updateLocale(locale);
    _saveLocaleToPrefs(lang.code);
  }


  void changeLocale(String languageCode) {
    final locale = Locale(languageCode, languageCode == 'en' ? 'US' : 'SA');
    _locale.value = locale;
    Get.updateLocale(locale);
    // حفظ اللغة المختارة
    _saveLocaleToPrefs(languageCode);
  }
  void toggleLanguage() {
    if (isArabic) {
      changeLocale('en');
    } else {
      changeLocale('ar');
    }
  }
  void _saveLocaleToPrefs(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  void _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_keyLanguage);

    if (savedCode == null) return;

    final lang = languages.firstWhereOrNull((l) => l.code == savedCode);
    if (lang != null) {
      final locale = Locale(lang.language, lang.country);
      _locale.value = locale;
      Get.updateLocale(locale);
    }
  }

  bool get isArabic => _locale.value.languageCode == 'ar';
  bool get isEnglish => _locale.value.languageCode == 'en';
  bool get isRTL => isArabic;
}
