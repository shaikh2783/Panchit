import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/notifications/data/models/notifications_response.dart';

class NotificationsApiService {
  NotificationsApiService(this._client);

  final ApiClient _client;

  /// Fetch notifications with pagination
  Future<NotificationsResponse> getNotifications({
    int offset = 0,
    int limit = 20,
    int? lastNotificationId,
  }) async {
    
    final params = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
    };

    if (lastNotificationId != null) {
      params['last_notification_id'] = lastNotificationId.toString();
    }

    final response = await _client.get(
      configCfgP('notifications'),
      queryParameters: params,
    );


    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to fetch notifications',
        details: response,
      );
    }

    return NotificationsResponse.fromJson(response);
  }

  /// Mark a specific notification as read
  Future<void> markNotificationRead(int notificationId) async {
    try {
      final response = await _client.post(
        configCfgP('notifications_read'),
        body: {
          'notification_id': notificationId,
        },
      );

      if (response['status'] == 'success') {
      }
    } on ApiException catch (e) {
      // If the notification is already read, this is not an error - we'll ignore it silently
      if (e.message.toLowerCase().contains('already read')) {
        // لا نطبع شيء - العملية نجحت من منظور المستخدم
        return;
      }
      
      // Re-throw the error if it's a real error
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllNotificationsRead() async {
    
    final response = await _client.post(
      configCfgP('notifications_read'),
      body: {
        'mark_all': true,
      },
    );

    if (response['status'] != 'success') {
      throw ApiException(
        response['message'] ?? 'Failed to mark all notifications as read',
        details: response,
      );
    }

    final markedCount = response['data']?['marked_count'] as int? ?? 0;
    
    return markedCount;
  }
}
