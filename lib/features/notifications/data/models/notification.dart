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
    return NotificationModel(
      notificationId: json['notification_id'] as int,
      fromUserId: json['from_user_id'] as int,
      fromUserType: json['from_user_type'] as String,
      action: json['action'] as String,
      nodeType: json['node_type'] as String,
      nodeId: json['node_id'] as int?,
      nodeUrl: json['node_url'] as String,
      message: json['message'] as String,
      url: json['url'] as String,
      icon: json['icon'] as String?,
      seen: json['seen'] as bool? ?? false,
      time: json['time'] as String,
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
}
