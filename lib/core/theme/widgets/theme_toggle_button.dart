import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/theme/app_colors.dart';
import 'package:snginepro/core/theme/theme_controller.dart';
/// زر تبديل بين الوضع الفاتح والداكن
/// يمكن وضعه في AppBar أو أي مكان في التطبيق
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            key: ValueKey(isDark),
            color: isDark ? Colors.amber : AppColors.primary,
          ),
        ),
        onPressed: () async {
          await themeController.toggleTheme();
          // إظهار رسالة قصيرة
          Get.snackbar(
            '',
            '',
            titleText: const SizedBox.shrink(),
            messageText: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isDark ? 'تم التبديل للوضع الفاتح' : 'تم التبديل للوضع الداكن',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.black87,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
          );
        },
        tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
      );
    });
  }
}
/// زر Switch لتبديل الثيم - مناسب للإعدادات
class ThemeToggleSwitch extends StatelessWidget {
  const ThemeToggleSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      return SwitchListTile(
        title: const Text('الوضع الداكن'),
        subtitle: Text(
          isDark ? 'تم التفعيل' : 'تم التعطيل',
        ),
        secondary: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? Colors.amber : AppColors.primary,
        ),
        value: isDark,
        onChanged: (value) async {
          await themeController.setDarkMode(value);
        },
        activeThumbColor: AppColors.primary,
      );
    });
  }
}
/// قائمة خيارات الثيم - مناسبة للإعدادات
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      return Column(
        children: [
          RadioListTile<bool>(
            title: const Text('الوضع الفاتح'),
            subtitle: const Text('مناسب للاستخدام النهاري'),
            secondary: const Icon(Icons.light_mode, color: Colors.amber),
            value: false,
            groupValue: isDark,
            onChanged: (value) async {
              if (value != null) {
                await themeController.setDarkMode(value);
              }
            },
            activeColor: AppColors.primary,
          ),
          RadioListTile<bool>(
            title: const Text('الوضع الداكن'),
            subtitle: const Text('مناسب للاستخدام الليلي'),
            secondary: Icon(Icons.dark_mode, color: AppColors.primary),
            value: true,
            groupValue: isDark,
            onChanged: (value) async {
              if (value != null) {
                await themeController.setDarkMode(value);
              }
            },
            activeColor: AppColors.primary,
          ),
        ],
      );
    });
  }
}
/// زر عائم لتبديل الثيم
class ThemeToggleFAB extends StatelessWidget {
  const ThemeToggleFAB({super.key});
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    return Obx(() {
      final isDark = themeController.isDarkMode;
      return FloatingActionButton(
        mini: true,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        onPressed: () => themeController.toggleTheme(),
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: isDark ? Colors.amber : AppColors.primary,
        ),
      );
    });
  }
}
