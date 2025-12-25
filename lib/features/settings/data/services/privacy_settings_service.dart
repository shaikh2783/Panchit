import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/privacy_settings_model.dart';

/// خدمة إدارة إعدادات الخصوصية والإشعارات
class PrivacySettingsService {
  final ApiClient _apiClient;

  PrivacySettingsService(this._apiClient);

  /// جلب إعدادات الخصوصية الحالية
  Future<PrivacySettings> getSettings() async {
    try {

      final response = await _apiClient.get(configCfgP('settings_privacy'));

      if (response['status'] == 'success') {
        return PrivacySettings.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch settings');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث إعدادات الخصوصية
  Future<void> updatePrivacySettings(Map<String, dynamic> privacy) async {
    try {

      final response = await _apiClient.post(
        configCfgP('settings_privacy'),
        data: {'privacy': privacy},
      );

      if (response['status'] == 'success') {
        if (response['data'] != null &&
            response['data']['updated_fields'] != null) {
          final updatedFields = response['data']['updated_fields'] as List;
        }
      } else {
        throw Exception(
          response['message'] ?? 'Failed to update privacy settings',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث إعدادات الإشعارات
  Future<void> updateNotificationSettings(
    Map<String, dynamic> notifications,
  ) async {
    try {

      final response = await _apiClient.post(
        configCfgP('settings_privacy'),
        data: {'notifications': notifications},
      );

      if (response['status'] == 'success') {
        if (response['data'] != null &&
            response['data']['updated_fields'] != null) {
          final updatedFields = response['data']['updated_fields'] as List;
        }
      } else {
        throw Exception(
          response['message'] ?? 'Failed to update notification settings',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث إعداد خصوصية واحد
  Future<void> updatePrivacyField(String field, String value) async {
    return updatePrivacySettings({field: value});
  }

  /// تحديث إعداد إشعار واحد
  Future<void> toggleNotification(String field, bool value) async {
    return updateNotificationSettings({field: value});
  }

  /// تحديث إعدادات الخصوصية والإشعارات معاً
  Future<void> updateAllSettings({
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? notifications,
  }) async {
    try {
      if (privacy == null && notifications == null) {
        throw Exception('No settings to update');
      }


      final data = <String, dynamic>{};
      if (privacy != null) data['privacy'] = privacy;
      if (notifications != null) data['notifications'] = notifications;

      final response = await _apiClient.post(
        configCfgP('settings_privacy'),
        data: data,
      );

      if (response['status'] == 'success') {
        if (response['data'] != null &&
            response['data']['updated_fields'] != null) {
          final updatedFields = response['data']['updated_fields'] as List;
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update settings');
      }
    } catch (e) {
      rethrow;
    }
  }
}
