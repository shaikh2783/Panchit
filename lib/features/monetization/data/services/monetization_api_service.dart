import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/monetization_settings.dart';
import '../models/monetization_payment.dart';
import '../models/monetization_earning.dart';

/// خدمة API لتحقيق الدخل
class MonetizationApiService {
  final ApiClient _apiClient;

  MonetizationApiService(this._apiClient);

  /// الحصول على إعدادات تحقيق الدخل
  Future<Map<String, dynamic>> getMonetizationSettings() async {
    try {
      final response = await _apiClient.get(
        configCfgP('monetization_settings'),
      );

      if (response['error'] == false) {
        return {
          'success': true,
          'settings': MonetizationSettings.fromJson(response['data']),
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to load settings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// تحديث إعدادات تحقيق الدخل
  Future<Map<String, dynamic>> updateMonetizationSettings({
    required bool enabled,
    required double chatPrice,
    required double callPrice,
  }) async {
    try {
      final requestBody = {
        'user_monetization_enabled': enabled,
        'user_monetization_chat_price': chatPrice,
        'user_monetization_call_price': callPrice,
      };

      final response = await _apiClient.post(
        configCfgP('monetization_update_settings'),
        body: requestBody,
      );

      return {
        'success': response['error'] == false,
        'message': response['message'] ?? 'Unknown error',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// الحصول على سجل المدفوعات
  Future<Map<String, dynamic>> getPayments() async {
    try {
      final response = await _apiClient.get(
        configCfgP('monetization_payments'),
      );

      if (response['error'] == false) {
        final payments = (response['data'] as List)
            .map((p) => MonetizationPayment.fromJson(p))
            .toList();

        return {'success': true, 'payments': payments};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to load payments',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// الحصول على سجل الأرباح
  Future<Map<String, dynamic>> getEarnings() async {
    try {
      final response = await _apiClient.get(
        configCfgP('monetization_earnings'),
      );

      if (response['error'] == false) {
        final earnings = (response['data'] as List)
            .map((e) => MonetizationEarning.fromJson(e))
            .toList();

        return {'success': true, 'earnings': earnings};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to load earnings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// الحصول على خطط الاشتراك
  Future<Map<String, dynamic>> getPlans({
    String? nodeId,
    String? nodeType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (nodeId != null) queryParams['node_id'] = nodeId;
      if (nodeType != null) queryParams['node_type'] = nodeType;

      final response = await _apiClient.get(
        configCfgP('monetization_plans'),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response['error'] == false) {
        final plans = (response['data'] as List)
            .map((p) => MonetizationPlan.fromJson(p))
            .toList();

        return {'success': true, 'plans': plans};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to load plans',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
