import 'package:get/get.dart';
import 'package:snginepro/features/notifications/data/models/notification_user.dart';

class NotificationModel {
  final int notificationId;
  final int fromUserId;
  final String fromUserType;
  final String action;
  final String nodeType;
  final int? nodeId;
  final String nodeUrl;
  final String message;
  final String? messageKey; // 🌐 Key for translation
  final String url;
  final String? icon;
  final bool seen;
  final String time;
  final String? insertTime;
  final NotificationUser user;
  final String? reaction;
  final bool? systemNotification;

  NotificationModel({
    required this.notificationId,
    required this.fromUserId,
    required this.fromUserType,
    required this.action,
    required this.nodeType,
    this.nodeId,
    required this.nodeUrl,
    required this.message,
    this.messageKey,
    required this.url,
    this.icon,
    required this.seen,
    required this.time,
    this.insertTime,
    required this.user,
    this.reaction,
    this.systemNotification,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v, {int defaultValue = 0}) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? defaultValue;
    }

    int? _parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return NotificationModel(
      notificationId: _parseInt(json['notification_id']),
      fromUserId: _parseInt(json['from_user_id']),
      fromUserType: (json['from_user_type'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      nodeType: (json['node_type'] ?? '').toString(),
      nodeId: _parseNullableInt(json['node_id']),
      nodeUrl: (json['node_url'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      messageKey: json['message_key'] as String?,
      url: (json['url'] ?? '').toString(),
      icon: json['icon'] as String?,
      seen: json['seen'] as bool? ?? false,
      time: (json['time'] ?? '').toString(),
      insertTime: json['insert_time'] as String?,
      user: NotificationUser.fromJson(json['user'] as Map<String, dynamic>),
      reaction: json['reaction'] as String?,
      systemNotification: json['system_notification'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'from_user_id': fromUserId,
      'from_user_type': fromUserType,
      'action': action,
      'node_type': nodeType,
      'node_id': nodeId,
      'node_url': nodeUrl,
      'message': message,
      'message_key': messageKey,
      'url': url,
      'icon': icon,
      'seen': seen,
      'time': time,
      'insert_time': insertTime,
      'user': user.toJson(),
      'reaction': reaction,
      'system_notification': systemNotification,
    };
  }

  /// Helper to get emoji for reaction
  String? get reactionEmoji {
    if (reaction == null) return null;
    switch (reaction) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😄';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'yay':
        return '🎉';
      default:
        return null;
    }
  }

  /// Helper to check if this is a reaction notification
  bool get isReaction => action.startsWith('react_');

  /// Create a copy with updated seen status
  NotificationModel copyWith({bool? seen}) {
    return NotificationModel(
      notificationId: notificationId,
      fromUserId: fromUserId,
      fromUserType: fromUserType,
      action: action,
      nodeType: nodeType,
      nodeId: nodeId,
      nodeUrl: nodeUrl,
      message: message,
      messageKey: messageKey,
      url: url,
      icon: icon,
      seen: seen ?? this.seen,
      time: time,
      insertTime: insertTime,
      user: user,
      reaction: reaction,
      systemNotification: systemNotification,
    );
  }

  /// 🌐 Get translated message or fallback to original message
  String get translatedMessage {
    if (messageKey != null && messageKey!.isNotEmpty) {
      // Convert "notification.started_following" to "notification_started_following"
      final key = messageKey!.replaceAll('.', '_');
      final translated = key.tr;
      // If translation exists (not same as key), use it
      if (translated != key) {
        return translated;
      }
    }
    // Fallback to original message from API
    return message;
  }
}
