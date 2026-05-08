import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snginepro/features/feed/presentation/pages/post_detail_page.dart';
import 'package:snginepro/features/notifications/presentation/pages/notifications_page.dart';
import 'package:snginepro/features/profile/presentation/pages/profile_page.dart';
import 'package:snginepro/features/settings/presentation/pages/manage_sessions_page.dart';
import 'package:snginepro/features/competitions/presentation/pages/competition_detail_page.dart';
import 'package:snginepro/features/wallet/presentation/pages/wallet_page.dart';

/// خدمة التنقل من الإشعارات
/// تتعامل مع جميع أنواع الإشعارات المدعومة في النظام
class NotificationNavigationService {
  /// Reference لـ navigatorKey من App لتجنب تضارب GlobalKey
  static late GlobalKey<NavigatorState> navigatorKey;
  static Map<String, dynamic>? _queuedData;
  static bool _isNavigationReady = false;
  static bool _isShowingSecurityAlert = false;

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

  static Future<void> handleForegroundNotification({
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
  }) async {
    if (!_isNewLoginAlert(title: title, data: data)) {
      return;
    }
    if (_isShowingSecurityAlert) {
      return;
    }

    final context = navigatorKey.currentContext ?? Get.context;
    if (context == null) {
      return;
    }

    _isShowingSecurityAlert = true;
    try {
      final shouldReviewSessions = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title ?? 'New Login Alert'),
          content: Text(
            body ??
                'A new sign-in to your account was detected. Review your active sessions to secure your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Review Sessions'),
            ),
          ],
        ),
      );

      if (shouldReviewSessions == true) {
        handleNotification(data);
      }
    } finally {
      _isShowingSecurityAlert = false;
    }
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

        case 'competitions':
        case 'competition':
          if (pathSegments.length > 1) {
            final competitionId = int.tryParse(pathSegments[1]) ?? 0;
            if (competitionId > 0) {
              Get.to(() => CompetitionDetailPage(competitionId: competitionId));
            }
          }
          break;

        case 'wallet':
          Get.to(() => const WalletPage());
          break;

        case 'settings':
          if (pathSegments.length > 1 && pathSegments[1] == 'sessions') {
            Get.to(() => const ManageSessionsPage());
          }
          break;
          
        default:
      }
    } catch (e) {
      // Ignore malformed deep links and keep the current screen intact.
    }
  }

  static bool _isNewLoginAlert({
    required String? title,
    required Map<String, dynamic> data,
  }) {
    final url = (data['url'] ?? data['u'] ?? data['launchURL'])?.toString();
    if (_isSessionsUrl(url)) {
      return true;
    }

    final normalizedTitle = title?.toLowerCase().trim();
    if (normalizedTitle == null || normalizedTitle.isEmpty) {
      return false;
    }
    return normalizedTitle.contains('new login alert');
  }

  static bool _isSessionsUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }

    try {
      final processedUrl = url.contains('://')
          ? url
          : url.startsWith('/')
              ? 'https://app.local$url'
              : 'https://app.local/$url';
      final uri = Uri.parse(processedUrl);
      final segments = uri.pathSegments;
      return segments.length >= 2 &&
          segments[0] == 'settings' &&
          segments[1] == 'sessions';
    } catch (_) {
      return false;
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

      case 'competition_started':
      case 'competition_cancelled':
      case 'competition_voting_started':
      case 'competition_winner':
        final competitionId = int.tryParse(
              (data['competition_id'] ?? data['id'] ?? data['node_id'])
                      ?.toString() ??
                  '',
            ) ??
            0;
        if (competitionId > 0) {
          Get.to(() => CompetitionDetailPage(competitionId: competitionId));
        } else {
          Get.to(() => const NotificationsPage());
        }
        break;

      case 'competition_refund':
        final refundCompetitionId = int.tryParse(
              (data['competition_id'] ?? data['id'])?.toString() ?? '',
            ) ??
            0;
        if (refundCompetitionId > 0) {
          Get.to(() => CompetitionDetailPage(competitionId: refundCompetitionId));
        } else {
          Get.to(() => const WalletPage());
        }
        break;
        
      // إشعارات أخرى
      default:
        Get.to(() => const NotificationsPage());
    }
  }
}
