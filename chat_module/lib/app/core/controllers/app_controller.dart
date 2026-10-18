import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../settings.dart';
import '../storage/app_preferences.dart';

class AppController extends GetxController {
  AppController(this._preferences);

  final ChatAppPreferences _preferences;
  // Defaults to whatever the host app (see home_page.dart) is already
  // showing until the user explicitly picks a mode from Settings.
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
    if (saved != null) {
      themeMode.value = switch (saved) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      return;
    }

    // No explicit choice made from inside chat yet: follow the host app's
    // current dark/light mode instead of defaulting to light.
    final hostIsDark = _preferences.getHostDarkMode() ?? Get.isDarkMode;
    themeMode.value = hostIsDark ? ThemeMode.dark : ThemeMode.light;
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
    // Keep the host app's own theme switch (home_page.dart / ThemeController)
    // in sync so the choice made here isn't reverted on the next app launch.
    if (mode != ThemeMode.system) {
      await _preferences.setHostDarkMode(mode == ThemeMode.dark);
    }
    Get.changeThemeMode(themeMode.value);
  }

  void syncAppIdentityFromRuntime() {
    appDisplayName.value = appName.isNotEmpty ? appName : defaultAppName;
    appDisplayLogo.value = appLogo;
  }
}
