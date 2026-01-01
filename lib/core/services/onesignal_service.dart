import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;

/// خدمة OneSignal - إدارة Player ID وإرساله للسيرفر
class OneSignalService {
  final ApiClient _apiClient;

  OneSignalService(this._apiClient);

  /// محاولة الحصول على Player ID من OneSignal مع إعادة المحاولة
  Future<String?> getPlayerId({int maxRetries = 20}) async {
    try {
      String? playerId = OneSignal.User.pushSubscription.id;
      if (playerId != null && playerId.isNotEmpty) {

        return playerId;
      }

      for (int i = 0; i < maxRetries; i++) {
        // تزايد بسيط في الانتظار: 1s, 2s, 3s ...
        await Future.delayed(Duration(seconds: i + 1));
        playerId = OneSignal.User.pushSubscription.id;
        if (playerId != null && playerId.isNotEmpty) {

          return playerId;
        }

      }

      return null;
    } catch (e) {

      return null;
    }
  }

  /// تسجيل Player ID الحالي مع الخادم
  Future<bool> registerCurrentPlayerId() async {
    final playerId = await getPlayerId();
    if (playerId == null || playerId.isEmpty) {

      return false;
    }
    return updateOneSignalPlayerId(playerId);
  }

  /// إرسال Player ID إلى API
  Future<bool> updateOneSignalPlayerId(String playerId) async {
    try {

      final response = await _apiClient
          .post(
            configCfgP('user_onesignal'),
            body: {
              'onesignal_id': playerId,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {

              return {
                'status': 'error',
                'message': 'timeout',
              };
            },
          );

      if (response['status'] == 'success') {

        return true;
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  /// حذف Player ID من الخادم (عند تسجيل الخروج)
  Future<bool> removeOneSignalPlayerId() async {
    try {

      final response = await _apiClient.post(
        configCfgP('user_onesignal'),
        body: {
          'onesignal_id': '',
        },
      );

      if (response['status'] == 'success') {

        return true;
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }
}
