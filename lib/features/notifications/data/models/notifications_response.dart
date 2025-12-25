import 'package:snginepro/features/notifications/data/models/notification.dart';

class NotificationsResponse {
  final String status;
  final NotificationsData data;

  NotificationsResponse({
    required this.status,
    required this.data,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      status: json['status'] as String,
      data: NotificationsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.toJson(),
    };
  }
}

class NotificationsData {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int total;

  NotificationsData({
    required this.notifications,
    required this.unreadCount,
    required this.total,
  });

  factory NotificationsData.fromJson(Map<String, dynamic> json) {
    return NotificationsData(
      notifications: (json['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'unread_count': unreadCount,
      'total': total,
    };
  }
}
