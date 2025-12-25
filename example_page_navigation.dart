// مثال على كيفية استخدام PageProfilePage مع pageId فقط
import 'package:flutter/material.dart';
import 'lib/features/pages/presentation/pages/page_profile_page.dart';
import 'lib/features/pages/data/models/page.dart';

/// مثال على كيفية التنقل إلى صفحة الشركة/المنظمة
class PageNavigationExample {
  
  /// الطريقة القديمة: عندما تكون بيانات الصفحة متوفرة
  static void navigateWithPageModel(BuildContext context, PageModel page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageProfilePage(page: page),
      ),
    );
  }
  
  /// الطريقة الجديدة: عند الوصول من الإشعارات أو عبر pageId فقط
  static void navigateWithPageId(BuildContext context, int pageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageProfilePage.fromId(pageId: pageId),
      ),
    );
  }
}

/// مثال على استخدام الصفحة في الإشعارات
class NotificationHandler {
  static void handlePageNotification(BuildContext context, Map<String, dynamic> notificationData) {
    // إذا كانت الإشعارة تحتوي على page_id
    final pageId = notificationData['page_id'] as int?;
    
    if (pageId != null) {
      // استخدام Constructor الجديد
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PageProfilePage.fromId(pageId: pageId),
        ),
      );
    }
  }
}

/// مثال على التنقل من قائمة البحث
class SearchPageResult extends StatelessWidget {
  final int pageId;
  final String pageName;
  
  const SearchPageResult({
    Key? key,
    required this.pageId,
    required this.pageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(pageName),
      onTap: () {
        // التنقل مع pageId فقط
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PageProfilePage.fromId(pageId: pageId),
          ),
        );
      },
    );
  }
}