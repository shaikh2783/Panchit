import '../../../../core/network/api_client.dart';
import '../models/funding_payment.dart';
import '../models/funding_settings.dart';
import '../models/funding_stats.dart';

/// Funding Settings API Service
/// خدمة API لإدارة رصيد التمويل والسحب والتحويل
class FundingSettingsApiService {
  final ApiClient _apiClient;

  FundingSettingsApiService(this._apiClient);

  /// جلب إعدادات التمويل والرصيد
  /// GET /data/funding/settings/info
  /// fallback: /data/funding/settings (compat)
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final paths = ['/data/funding/settings/info', '/data/funding/settings'];
      for (final path in paths) {
        try {
          final response = await _apiClient.get(path);
          final isError = response['error'] == true;

          if (!isError && response['data'] != null) {
            final settings = FundingSettings.fromJson(
              response['data'] is Map<String, dynamic>
                  ? response['data']
                  : <String, dynamic>{},
            );
            return {
              'success': true,
              'data': settings,
            };
          }
        } catch (e) {
          // try next path
        }
      }

      return {
        'success': false,
        'message': 'Failed to load funding settings',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// جلب سجل طلبات السحب
  /// GET /data/funding/settings/payments
  Future<Map<String, dynamic>> getPayments() async {
    try {

      final response = await _apiClient.get('/data/funding/settings/payments');
      final isError = response['error'] == true;

      if (!isError && response['data'] != null) {
        final payments = <FundingPayment>[];

        if (response['data'] is List) {
          for (final item in response['data']) {
            if (item is Map<String, dynamic>) {
              payments.add(FundingPayment.fromJson(item));
            }
          }
        }

        return {
          'success': true,
          'data': payments,
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load payments',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// إنشاء طلب سحب جديد
  /// POST /data/funding/settings/withdraw
  Future<Map<String, dynamic>> submitWithdrawal({
    required double amount,
    required String method,
    required String methodValue,
    String? bankDetails,
  }) async {
    try {

      final payload = {
        'amount': amount,
        'method': method,
        'method_value': methodValue,
      };

      if (bankDetails != null && bankDetails.isNotEmpty) {
        payload['bank_details'] = bankDetails;
      }

      final response = await _apiClient.post(
        '/data/funding/settings/withdraw',
        body: payload,
      );

      final isError = response['error'] == true;
      if (!isError) {
        return {
          'success': true,
          'message': response['message'] ?? 'Withdrawal request submitted',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Withdrawal request failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// تحويل رصيد التمويل إلى المحفظة
  /// POST /data/funding/settings/transfer
  Future<Map<String, dynamic>> transferToWallet(double amount) async {
    try {

      final response = await _apiClient.post(
        '/data/funding/settings/transfer',
        body: {'amount': amount},
      );

      final isError = response['error'] == true;
      if (!isError) {
        return {
          'success': true,
          'message': response['message'] ?? 'Transfer completed',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Transfer failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// إحصاءات التمويل
  /// GET /data/funding/settings/stats
  /// fallback: /data/funding/settings/statistics (compat)
  Future<Map<String, dynamic>> getStats() async {
    try {
      final paths = ['/data/funding/settings/stats', '/data/funding/settings/statistics'];
      for (final path in paths) {
        try {
          final response = await _apiClient.get(path);
          final isError = response['error'] == true;

          if (!isError && response['data'] != null) {
            final stats = FundingStats.fromJson(
              response['data'] is Map<String, dynamic>
                  ? response['data']
                  : <String, dynamic>{},
            );
            return {
              'success': true,
              'data': stats,
            };
          }
        } catch (e) {
          // try next path
        }
      }

      return {
        'success': false,
        'message': 'Failed to load stats',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
