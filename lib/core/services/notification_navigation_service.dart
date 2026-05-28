import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/feed/presentation/pages/post_detail_page.dart';
import 'package:snginepro/features/notifications/presentation/pages/notifications_page.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';

/// خدمة التنقل من الإشعارات
/// تتعامل مع جميع أنواع الإشعارات المدعومة في النظام
class NotificationNavigationService {
  /// Reference لـ navigatorKey من App لتجنب تضارب GlobalKey
  static late GlobalKey<NavigatorState> navigatorKey;
  static Map<String, dynamic>? _queuedData;
  static bool _isNavigationReady = false;

  /// يجب استدعاؤها بعد بناء التطبيق (مثلاً بعد runApp) لتفعيل التنقل
  static void markAppReady() {
    _isNavigationReady = true;
    if (_queuedData != null) {
      final data = _queuedData!;
      _queuedData = null;
      // استخدام microtask بدلاً من Future.delayed لتفادي تأخيرات غير ضرورية
      Future.microtask(() => _process(data));
    }
  }

  /// معالجة التنقل من بيانات الإشعار
  static void handleNotification(Map<String, dynamic> data) {
    // في حالة الفتح البارد (التطبيق مغلق) نخزن الطلب حتى يصبح الـ Navigator جاهز
    if (!_isNavigationReady) {
      _queuedData = data;
      return;
    }

    _process(data);
  }

  static void _process(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final url = (data['url'] ?? data['u'] ?? data['launchURL']) as String?;
    
    
    // Double-check that GetX context is ready
    if (Get.context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _process(data);
      });
      return;
    }
    
    // Priority 1: Try URL if available
    if (url != null && url.isNotEmpty) {
      _navigateFromUrl(url);
      return;
    }
    
    // Priority 2: Try type-based navigation
    if (type != null) {
      _navigateFromType(type, data);
      return;
    }
    
    // Priority 3: Fallback to node_type and node_id
    final nodeType = data['node_type'];
    final nodeId = (data['node_id'] ?? data['post_id'])?.toString();
    
    if (nodeType == 'post' && nodeId != null && nodeId.isNotEmpty) {
      final postIdInt = int.tryParse(nodeId) ?? 0;
      if (postIdInt > 0) {
        Get.to(() => PostDetailPage(postId: postIdInt));
        return;
      }
    }
    
    // No valid navigation found
  }
  
  /// التنقل بناءً على URL
  static void _navigateFromUrl(String url) {
    try {
      // Handle deep links (sngine_timeline://, sngine://) and regular URLs
      String processedUrl = url;
      
      // Convert deep link to regular URL format for easier parsing
      if (url.contains('sngine_timeline://')) {
        processedUrl = url.replaceFirst('sngine_timeline://', 'https://');
      } else if (url.contains('sngine://')) {
        processedUrl = url.replaceFirst('sngine://', 'https://');
      }
      
      
      final uri = Uri.parse(processedUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) {
        return;
      }
      
      final firstSegment = pathSegments[0];
      
      switch (firstSegment) {
        // 📄 منشورات
        case 'posts':
          if (pathSegments.length > 1) {
            final postId = pathSegments[1];
            final id = int.tryParse(postId) ?? 0;
            if (id > 0) {
              Get.to(() => PostDetailPage(postId: id));
            } else {
            }
          }
          break;
          
        // 👤 ملفات شخصية
        case 'users':
        case 'profile':
          if (pathSegments.length > 1) {
            final username = pathSegments[1];
            Get.to(() => ProfilePage(username: username));
          }
          break;
          
        // 💬 إشعارات
        case 'notifications':
          Get.to(() => const NotificationsPage());
          break;
          
        default:
      }
    } catch (e) {
    }
  }
  
  /// التنقل بناءً على النوع
  static void _navigateFromType(String type, Map<String, dynamic> data) {
    final id = data['id'];
    final nodeId = data['node_id'] ?? data['post_id'];
    final username = data['from_user_name'];
    
    switch (type) {
      // 🤝 التواصل الاجتماعي
      case 'friend_add':
      case 'friend_accept':
      case 'follow':
      case 'poke':
      case 'gift':
      case 'profile_visit':
        if (username != null) {
          Get.to(() => ProfilePage(username: username));
        }
        break;
        
      // ❤️ تفاعلات المنشورات
      case 'like':
      case 'react_like':
      case 'react_love':
      case 'react_haha':
      case 'react_yay':
      case 'react_wow':
      case 'react_sad':
      case 'react_angry':
      case 'comment':
      case 'reply':
      case 'share':
      case 'vote':
      case 'mention':
      case 'wall':
        // Try to get post ID from multiple possible fields
        final postId = int.tryParse((nodeId ?? id)?.toString() ?? '') ?? 0;
        if (postId > 0) {
          Get.to(() => PostDetailPage(postId: postId));
        } else {
        }
        break;
        
      // 🔔 إشعارات
      case 'notification':
      case 'system_notification':
        Get.to(() => const NotificationsPage());
        break;
        
      // إشعارات أخرى
      default:
        Get.to(() => const NotificationsPage());
    }
  }
}

