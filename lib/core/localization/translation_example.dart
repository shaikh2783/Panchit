import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
/// مثال على كيفية استخدام نظام الترجمة مع GetX
class TranslationExampleWidget extends StatelessWidget {
  const TranslationExampleWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr), // يترجم إلى "الإعدادات" أو "Settings"
        actions: [
          // زر تغيير اللغة
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              localizationController.toggleLanguage();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مثال على استخدام الترجمة
            Text(
              'welcome'.tr, // مرحباً / Welcome
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'language'.tr, // اللغة / Language
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // عرض اللغة الحالية
            Text(
              localizationController.isArabic 
                  ? 'arabic'.tr 
                  : 'english'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // أزرار الإجراءات
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('save'.tr), // حفظ / Save
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {},
                  child: Text('cancel'.tr), // إلغاء / Cancel
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
/// مثال على استخدام الترجمة في المنشورات
class PostActionsExample extends StatelessWidget {
  const PostActionsExample({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          icon: const Icon(Icons.thumb_up_outlined),
          label: Text('like'.tr), // إعجاب / Like
          onPressed: () {},
        ),
        TextButton.icon(
          icon: const Icon(Icons.comment_outlined),
          label: Text('comment'.tr), // تعليق / Comment
          onPressed: () {},
        ),
        TextButton.icon(
          icon: const Icon(Icons.share_outlined),
          label: Text('share'.tr), // مشاركة / Share
          onPressed: () {},
        ),
      ],
    );
  }
}
/// مثال على كيفية التحقق من حالة التعليقات
class CommentsStatusExample extends StatelessWidget {
  final bool commentsEnabled;
  const CommentsStatusExample({
    Key? key,
    required this.commentsEnabled,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (!commentsEnabled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.comments_disabled,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'comments_disabled'.tr, // التعليقات معطلة لهذا المنشور
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}