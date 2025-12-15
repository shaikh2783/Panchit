import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
class LanguageTestPage extends StatelessWidget {
  const LanguageTestPage({super.key});
  @override
  Widget build(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('menu'.tr),
        actions: [
          IconButton(
            onPressed: () {
              localizationController.toggleLanguage();
              Get.snackbar(
                'language'.tr,
                'language_switch_success'.tr,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: GetBuilder<LocalizationController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Language: ${controller.isArabic ? "العربية" : "English"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Test translations
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('menu'.tr, style: const TextStyle(fontSize: 16)),
                      Text('settings'.tr, style: const TextStyle(fontSize: 16)),
                      Text('home'.tr, style: const TextStyle(fontSize: 16)),
                      Text('profile'.tr, style: const TextStyle(fontSize: 16)),
                      Text('notifications'.tr, style: const TextStyle(fontSize: 16)),
                      Text('search'.tr, style: const TextStyle(fontSize: 16)),
                      Text('quick_actions'.tr, style: const TextStyle(fontSize: 16)),
                      Text('saved_posts'.tr, style: const TextStyle(fontSize: 16)),
                      Text('groups'.tr, style: const TextStyle(fontSize: 16)),
                      Text('coming_soon'.tr, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  localizationController.changeLocale('ar');
                },
                child: const Text('العربية'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  localizationController.changeLocale('en');
                },
                child: const Text('English'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}