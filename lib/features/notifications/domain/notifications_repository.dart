import 'package:snginepro/features/notifications/data/datasources/notifications_api_service.dart';
import 'package:snginepro/features/notifications/data/models/notifications_response.dart';

class NotificationsRepository {
  NotificationsRepository(this._apiService);

  final NotificationsApiService _apiService;

  /// Fetch notifications
  Future<NotificationsResponse> getNotifications({
    int offset = 0,
    int limit = 20,
    int? lastNotificationId,
  }) async {
    return await _apiService.getNotifications(
      offset: offset,
      limit: limit,
      lastNotificationId: lastNotificationId,
    );
  }

  /// Mark notification as read
  Future<void> markNotificationRead(int notificationId) async {
    return await _apiService.markNotificationRead(notificationId);
  }

  /// Delete a single notification
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    return await _apiService.deleteNotification(notificationId);
  }

  /// Delete all notifications (optionally seen only)
  Future<Map<String, dynamic>> deleteAllNotifications({bool seenOnly = false}) async {
    return await _apiService.deleteAllNotifications(seenOnly: seenOnly);
  }

  /// Mark all notifications as read
  Future<int> markAllNotificationsRead() async {
    return await _apiService.markAllNotificationsRead();
  }
}
