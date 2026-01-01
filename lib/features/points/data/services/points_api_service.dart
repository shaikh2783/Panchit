import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/points/data/models/points_payment.dart';
import 'package:snginepro/features/points/data/models/points_transaction.dart';
import 'package:flutter/foundation.dart';
import '../../../../main.dart' show configCfgP;

class PointsApiService {
  final ApiClient _apiClient;

  PointsApiService(this._apiClient);

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final endpoint = configCfgP('points_settings');

      final response = await _apiClient.get(endpoint);

      if (response['error'] == false && response['data'] != null) {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load points settings',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getTransactions({int offset = 0}) async {
    try {
      final endpoint = configCfgP('points_transactions');

      final response = await _apiClient.get('$endpoint?offset=$offset');

      if (response['error'] == false && response['data'] != null) {
        final data = response['data'];
        List<PointsTransaction> transactions = [];

        if (data is List) {
          transactions = data.map((e) {
            if (e is Map<String, dynamic>) {
              return PointsTransaction.fromJson(e);
            }
            return PointsTransaction.fromJson({});
          }).toList();
        }

        return {'success': true, 'data': transactions};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load transactions',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPayments({int offset = 0}) async {
    try {
      final endpoint = configCfgP('points_payments');

      final response = await _apiClient.get('$endpoint?offset=$offset');

      if (response['error'] == false && response['data'] != null) {
        final data = response['data'];
        List<PointsPayment> payments = [];

        if (data is List) {
          payments = data.map((e) {
            if (e is Map<String, dynamic>) {
              return PointsPayment.fromJson(e);
            }
            return PointsPayment.fromJson({});
          }).toList();
        }

        return {'success': true, 'data': payments};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load payments',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final endpoint = configCfgP('points_stats');

      final response = await _apiClient.get(endpoint);

      if (response['error'] == false && response['data'] != null) {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load points stats',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> submitWithdrawal({
    required double amount,
    required String method,
    required String methodValue,
  }) async {
    try {
      final endpoint = configCfgP('points_withdraw');

      final body = {
        'amount': amount,
        'method': method,
        'method_value': methodValue,
      };

      final response = await _apiClient.post(endpoint, data: body);

      if (response['error'] == false) {
        return {
          'success': true,
          'message': response['message'] ?? 'Withdrawal request submitted',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to submit withdrawal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
