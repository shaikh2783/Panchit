import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
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
      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        final locale = Locale(
          savedLanguage,
          savedLanguage == 'en' ? 'US' : 'SA',
        );
        _locale.value = locale;
        Get.updateLocale(locale);
      } else {
        // Default language is English
      }
    } catch (e) {
    }
  }
  bool get isArabic => _locale.value.languageCode == 'ar';
  bool get isEnglish => _locale.value.languageCode == 'en';
  bool get isRTL => isArabic;
}
