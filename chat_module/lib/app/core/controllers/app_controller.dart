import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../settings.dart';
import '../storage/app_preferences.dart';

class AppController extends GetxController {
  AppController(this._preferences);

  final ChatAppPreferences _preferences;
  // New installs open in the light reference design. People can still choose
  // system or dark explicitly from Settings.
  final themeMode = ThemeMode.light.obs;
  final appDisplayName = defaultAppName.obs;
  final appDisplayLogo = defaultAppLogo.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedThemeMode();
    syncAppIdentityFromRuntime();
  }

  void _loadSavedThemeMode() {
    final saved = _preferences.getThemeModeValue()?.trim().toLowerCase();
    themeMode.value = switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<void> toggleThemeMode(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final stored = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await _preferences.setThemeModeValue(stored);
    Get.changeThemeMode(themeMode.value);
  }

  void syncAppIdentityFromRuntime() {
    appDisplayName.value = appName.isNotEmpty ? appName : defaultAppName;
    appDisplayLogo.value = appLogo;
  }
}
