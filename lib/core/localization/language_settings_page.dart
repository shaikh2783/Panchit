import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('language'.tr), // اللغة / Language
        elevation: 0,
      ),
      body: GetBuilder<LocalizationController>(
        builder: (localizationController) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings'.tr, // الإعدادات / Settings
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'choose_language'.tr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Language Options
                Text(
                  'language'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // English Option
                _buildLanguageOption(
                  context: context,
                  title: 'english'.tr, // English
                  subtitle: 'English - United States',
                  languageCode: 'en',
                  flag: '��',
                  isSelected: localizationController.isEnglish,
                  onTap: () => localizationController.changeLocale('en'),
                ),
                const SizedBox(height: 12),
                // Arabic Option
                _buildLanguageOption(
                  context: context,
                  title: 'arabic'.tr, // العربية
                  subtitle: 'العربية - Saudi Arabia',
                  languageCode: 'ar',
                  flag: '🇸🇦',
                  isSelected: localizationController.isArabic,
                  onTap: () => localizationController.changeLocale('ar'),
                ),
                const SizedBox(height: 32),
                // Test Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.translate, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'translation_demo'.tr,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDemoRow('welcome'.tr, Icons.waving_hand),
                      _buildDemoRow('home'.tr, Icons.home),
                      _buildDemoRow('profile'.tr, Icons.person),
                      _buildDemoRow('notifications'.tr, Icons.notifications),
                      _buildDemoRow('settings'.tr, Icons.settings),
                    ],
                  ),
                ),
                const Spacer(),
                // Quick Toggle Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(
                      localizationController.isArabic 
                          ? 'switch_to_english'.tr
                          : 'switch_to_arabic'.tr,
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      localizationController.toggleLanguage();
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('language_changed'.tr),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String languageCode,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue[800] : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildDemoRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}