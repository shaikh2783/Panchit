import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;

/// خدمة إعدادات التطبيق - جلب إعدادات OneSignal والإعدادات الأخرى
class AppSettingsService {
  final ApiClient _apiClient;

  AppSettingsService(this._apiClient);

  /// جلب إعدادات التطبيق من API
  Future<AppSettings?> getAppSettings() async {
    try {

      final response = await _apiClient.get(configCfgP('app_settings'));

      if (response['status'] == 'success' && response['data'] != null) {
        final settings = AppSettings.fromJson(response['data']);

        return settings;
      } else {

        return null;
      }
    } catch (e) {

      return null;
    }
  }
}

/// نموذج إعدادات التطبيق
class AppSettings {
  final bool oneSignalEnabled;
  final String? oneSignalAppId;
  final String? oneSignalMessengerAppId;
  final String? oneSignalTimelineAppId;

  AppSettings({
    required this.oneSignalEnabled,
    this.oneSignalAppId,
    this.oneSignalMessengerAppId,
    this.oneSignalTimelineAppId,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // استخراج إعدادات النظام
    final system = json['system'] as Map<String, dynamic>? ?? {};

    return AppSettings(
      oneSignalEnabled: system['onesignal_notification_enabled'] == '1',
      oneSignalAppId: system['onesignal_app_id'] as String?,
      oneSignalMessengerAppId: system['onesignal_messenger_app_id'] as String?,
      oneSignalTimelineAppId: system['onesignal_timeline_app_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onesignal_notification_enabled': oneSignalEnabled,
      'onesignal_app_id': oneSignalAppId,
      'onesignal_messenger_app_id': oneSignalMessengerAppId,
      'onesignal_timeline_app_id': oneSignalTimelineAppId,
    };
  }
}
