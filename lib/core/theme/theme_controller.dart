import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller لإدارة الثيم والوضع الداكن في التطبيق
/// يستخدم GetX للإدارة الفعالة للحالة
class ThemeController extends GetxController {
  // حالة الوضع الداكن
  final _isDarkMode = true.obs;
  bool get isDarkMode => _isDarkMode.value;

  // مفتاح حفظ الإعداد
  static const String _themeKey = 'theme_mode';

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  /// تحميل الوضع المحفوظ من SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getBool(_themeKey);
      if (savedMode != null) {
        _isDarkMode.value = savedMode;
        _updateThemeMode();
      } else {
        _isDarkMode.value = true; // Default to dark on first launch
        await _saveThemeMode(true);
        _updateThemeMode();
      }
    } catch (e) {
    }
  }

  /// حفظ الوضع في SharedPreferences
  Future<void> _saveThemeMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
    }
  }

  /// تبديل الوضع بين الفاتح والداكن
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _saveThemeMode(_isDarkMode.value);
    _updateThemeMode();
  }

  /// تعيين الوضع الداكن
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode.value != isDark) {
      _isDarkMode.value = isDark;
      await _saveThemeMode(isDark);
      _updateThemeMode();
    }
  }

  /// تطبيق الوضع على GetX
  void _updateThemeMode() {
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// الحصول على لون النص الأساسي حسب الوضع
  Color get primaryTextColor => isDarkMode 
    ? const Color(0xFFE4E6EB) 
    : const Color(0xFF050505);

  /// الحصول على لون النص الثانوي حسب الوضع
  Color get secondaryTextColor => isDarkMode 
    ? const Color(0xFFB0B3B8) 
    : const Color(0xFF65676B);

  /// الحصول على لون الخلفية حسب الوضع
  Color get backgroundColor => isDarkMode 
    ? const Color(0xFF18191A) 
    : const Color(0xFFF0F2F5);

  /// الحصول على لون السطح حسب الوضع
  Color get surfaceColor => isDarkMode 
    ? const Color(0xFF242526) 
    : const Color(0xFFFFFFFF);

  /// الحصول على لون البطاقة حسب الوضع
  Color get cardColor => isDarkMode 
    ? const Color(0xFF3A3B3C) 
    : const Color(0xFFFFFFFF);

  /// الحصول على لون الفاصل حسب الوضع
  Color get dividerColor => isDarkMode 
    ? const Color(0xFF3E4042) 
    : const Color(0xFFE4E6EB);
}
