import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/two_factor_status.dart';

class TwoFactorApiService {
  final ApiClient _apiClient;

  TwoFactorApiService(this._apiClient);

  /// جلب حالة المصادقة الثنائية
  Future<Map<String, dynamic>> getStatus() async {
    try {

      final response = await _apiClient.get(configCfgP('two_factor_status'));


      if (response['status'] == 'success') {
        final data = response['data'];
        return {'success': true, 'status': TwoFactorStatus.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to get 2FA status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// تفعيل المصادقة الثنائية
  Future<Map<String, dynamic>> enable({String? code}) async {
    try {

      final body = code != null ? {'code': code} : <String, dynamic>{};

      final response = await _apiClient.post(
        configCfgP('two_factor_enable'),
        body: body,
      );


      if (response['status'] == 'success') {
        return {
          'success': true,
          'message': response['message'] ?? 'تم تفعيل المصادقة الثنائية بنجاح',
          'type': response['data']?['type'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل تفعيل المصادقة الثنائية',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// تعطيل المصادقة الثنائية
  Future<Map<String, dynamic>> disable() async {
    try {

      final response = await _apiClient.post(
        configCfgP('two_factor_disable'),
        body: {},
      );


      if (response['status'] == 'success') {
        return {
          'success': true,
          'message': response['message'] ?? 'تم تعطيل المصادقة الثنائية بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'فشل تعطيل المصادقة الثنائية',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
