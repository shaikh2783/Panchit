import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;

/// خدمة API للإحالات
class AffiliatesApiService {
  final ApiClient _apiClient;

  AffiliatesApiService(this._apiClient);

  /// الحصول على إعدادات الإحالات والإحصائيات
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiClient.get(configCfgP('affiliates_settings'));

      if (response['error'] == false) {
        return {'success': true, 'data': response['data'] ?? response};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch settings',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// الحصول على قائمة المستخدمين المحالين
  Future<Map<String, dynamic>> getAffiliatesList({int offset = 0}) async {
    try {
      final response = await _apiClient.get(
        configCfgP('affiliates_list'),
        queryParameters: {'offset': offset.toString()},
      );

      if (response['error'] == false) {
        return {'success': true, 'data': response['data'] ?? response};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch affiliates',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// الحصول على سجل المدفوعات
  Future<Map<String, dynamic>> getPayments() async {
    try {
      final response = await _apiClient.get(configCfgP('affiliates_payments'));

      if (response['error'] == false) {
        return {'success': true, 'data': response['data'] ?? response};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch payments',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// الحصول على الإحصائيات
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.get(configCfgP('affiliates_stats'));

      if (response['error'] == false) {
        return {'success': true, 'data': response['data'] ?? response};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch stats',
        };
      }
    } catch (e) {

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
