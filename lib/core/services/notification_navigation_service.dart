import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// خدمة التنقل من الإشعارات
/// تتعامل مع جميع أنواع الإشعارات المدعومة في النظام
class NotificationNavigationService {
  static Map<String, dynamic>? _queuedData;
  static bool _isNavigationReady = false;

  /// يجب استدعاؤها بعد بناء التطبيق (مثلاً بعد runApp) لتفعيل التنقل
  static void markAppReady() {
    _isNavigationReady = true;
    if (_queuedData != null) {
      final data = _queuedData!;
      _queuedData = null;
      _process(data);
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

    if (url != null && url.isNotEmpty) {
      _navigateFromUrl(url);
    } else if (type != null) {
      _navigateFromType(type, data);
    } else {
      // Fallback: if payload contains node info and it's a post, open post
      final nodeType = data['node_type'];
      final nodeId = data['node_id']?.toString();
      if (nodeType == 'post' && nodeId != null && nodeId.isNotEmpty) {

        Get.toNamed('/post/$nodeId', arguments: {'id': nodeId});
      }
    }
  }
  
  /// التنقل بناءً على URL
  static void _navigateFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.isEmpty) return;
      
      final firstSegment = pathSegments[0];
      
      switch (firstSegment) {
        // 📄 منشورات
        case 'posts':
          if (pathSegments.length > 1) {
            final postId = pathSegments[1];

            Get.toNamed('/post/$postId', arguments: {'id': postId});
          }
          break;
          
        // 📸 صور
        case 'photos':
          if (pathSegments.length > 1) {
            final photoId = pathSegments[1];

            Get.toNamed('/photo/$photoId');
          }
          break;
          
        // 💬 رسائل
        case 'messages':
          if (pathSegments.length > 1) {
            final conversationId = pathSegments[1];

            Get.toNamed('/messages/$conversationId');
          } else {

            Get.toNamed('/messages');
          }
          break;
          
        // 👥 مجموعات
        case 'groups':
          if (pathSegments.length > 1) {
            final groupName = pathSegments[1];

            Get.toNamed('/group/$groupName');
          } else {

            Get.toNamed('/groups');
          }
          break;
          
        // 📄 صفحات
        case 'pages':
          if (pathSegments.length > 1) {
            final pageName = pathSegments[1];

            Get.toNamed('/page/$pageName');
          } else {

            Get.toNamed('/pages');
          }
          break;
          
        // 🎉 أحداث
        case 'events':
          if (pathSegments.length > 1) {
            final eventId = pathSegments[1];

            Get.toNamed('/event/$eventId');
          } else {

            Get.toNamed('/events');
          }
          break;
          
        // 💰 سوق
        case 'market':
          if (pathSegments.length > 1) {
            final orderHash = pathSegments[1];

            Get.toNamed('/market/order/$orderHash');
          } else {

            Get.toNamed('/market');
          }
          break;
          
        // 👤 بروفايل (username)
        default:
          // If scheme is custom like sngine:// or sngine_timeline:// and path looks like posts/<id>
          if (firstSegment.isNotEmpty && pathSegments.length > 1 && firstSegment == 'posts') {
            final postId = pathSegments[1];

            Get.toNamed('/post/$postId', arguments: {'id': postId});
          } else {
            final username = firstSegment;

            Get.toNamed('/profile/$username');
          }
      }
    } catch (e) {

    }
  }
  
  /// التنقل بناءً على النوع
  static void _navigateFromType(String type, Map<String, dynamic> data) {
    final id = data['id'];
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

          Get.toNamed('/profile/$username');
        }
        break;
        
      // ❤️ تفاعلات المنشورات
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
        if (id != null) {

          Get.toNamed('/post/$id', arguments: {'id': id.toString()});
        }
        break;
        
      // 💬 رسائل
      case 'chat_message':
        if (id != null) {

          Get.toNamed('/messages/$id');
        } else {

          Get.toNamed('/messages');
        }
        break;
        
      // 👥 مجموعات
      case 'group_join':
      case 'group_add':
      case 'group_accept':
      case 'group_admin':
      case 'group_post_pending':
      case 'group_post_approval':
      case 'group_review':
      case 'group_review_reply':
        // fallback to post if node info exists
        final nodeType = data['node_type'];
        final nodeId = data['node_id']?.toString();
        if (nodeType == 'post' && nodeId != null && nodeId.isNotEmpty) {

          Get.toNamed('/post/$nodeId', arguments: {'id': nodeId});
        } else {
          final groupName = data['group_name'];
          if (groupName != null) {

            Get.toNamed('/group/$groupName');
          }
        }
        break;
        
      // 📄 صفحات
      case 'page_like':
      case 'page_admin':
      case 'page_review':
      case 'page_review_reply':
      case 'subscribe_page':
        // fallback to post if node info exists
        final nodeType = data['node_type'];
        final nodeId = data['node_id']?.toString();
        if (nodeType == 'post' && nodeId != null && nodeId.isNotEmpty) {

          Get.toNamed('/post/$nodeId', arguments: {'id': nodeId});
        } else {
          final pageName = data['page_name'];
          if (pageName != null) {

            Get.toNamed('/page/$pageName');
          }
        }
        break;
        
      // 🎉 أحداث
      case 'event_invite':
      case 'event_join':
      case 'event_post_pending':
      case 'event_post_approval':
      case 'event_review':
      case 'event_review_reply':
        // fallback to post if node info exists
        final nodeType = data['node_type'];
        final nodeId = data['node_id']?.toString();
        if (nodeType == 'post' && nodeId != null && nodeId.isNotEmpty) {

          Get.toNamed('/post/$nodeId', arguments: {'id': nodeId});
        } else if (id != null) {

          Get.toNamed('/event/$id');
        }
        break;
        
      // 💰 تجارة
      case 'market_order':
      case 'market_order_tracking_updated':
      case 'market_order_delivered':
        final orderHash = data['order_hash'];
        if (orderHash != null) {

          Get.toNamed('/market/order/$orderHash');
        }
        break;
        
      case 'market_outofstock':
      case 'paid_post':
      case 'funding_donation':
      case 'job_application':
      case 'course_application':
      case 'merit_received':
      case 'video_converted':
        if (id != null) {

          Get.toNamed('/post/$id');
        }
        break;
        
      // 🔔 إشعارات أخرى
      default:
        // Unknown: try node-based fallback then notifications
        final nodeType = data['node_type'];
        final nodeId = data['node_id']?.toString();
        if (nodeType == 'post' && nodeId != null && nodeId.isNotEmpty) {

          Get.toNamed('/post/$nodeId', arguments: {'id': nodeId});
        } else {

          Get.toNamed('/notifications');
        }
    }
  }
}
