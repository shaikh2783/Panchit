import '../../../../core/network/api_client.dart';
import '../models/market_settings.dart';
import '../models/market_payment.dart';
import '../models/market_stats.dart';

/// Market Settings & Payments API Service
/// خدمة API لإدارة رصيد البائع والدفعات والسحب

class MarketSettingsApiService {
  final ApiClient _apiClient;

  MarketSettingsApiService(this._apiClient);

  /// جلب إعدادات السوق والرصيد
  /// 
  /// GET /data/market/settings
  /// 
  /// يتحقق من:
  /// - رصيد البائع
  /// - صلاحيات السحب
  /// - طرق الدفع المتاحة
  /// - تفاصيل التحويل للمحفظة
  Future<Map<String, dynamic>> getSettings() async {
    try {

      final response = await _apiClient.get(
        '/data/market/settings',
      );

      final isError = response['error'] == true;

      if (!isError && response['data'] != null) {
        final settings = MarketSettings.fromJson(
          response['data'] is Map<String, dynamic>
              ? response['data']
              : <String, dynamic>{},
        );
        return {
          'success': true,
          'data': settings,
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load settings',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// جلب قائمة طلبات الدفع (السحب)
  /// 
  /// GET /data/market/payments
  /// 
  /// يرجع:
  /// - قائمة طلبات السحب السابقة
  /// - حالة كل طلب (معلق، موافق عليه، مرفوض)
  /// - طريقة الدفع والمبلغ والتاريخ
  Future<Map<String, dynamic>> getPayments() async {
    try {

      final response = await _apiClient.get(
        '/data/market/payments',
      );

      final isError = response['error'] == true;

      if (!isError && response['data'] != null) {
        final payments = <MarketPayment>[];

        if (response['data'] is List) {
          for (final item in response['data']) {
            if (item is Map<String, dynamic>) {
              payments.add(MarketPayment.fromJson(item));
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
  /// 
  /// POST /data/market/withdraw
  /// 
  /// المعاملات المطلوبة:
  /// - amount: المبلغ المراد سحبه (يجب أن يكون >= min_withdrawal وأقل من الرصيد)
  /// - method: طريقة الدفع (paypal, skrill, bank, custom)
  /// - method_value: البريد الإلكتروني أو رقم الحساب
  /// 
  /// التحقق من:
  /// - المبلغ > 0
  /// - المبلغ >= الحد الأدنى
  /// - المبلغ <= الرصيد
  /// - طريقة الدفع ضمن المتاح
  /// - صحة بيانات الدفع
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
        '/data/market/withdraw',
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

  /// تحويل الرصيد إلى المحفظة
  /// 
  /// POST /data/market/transfer
  /// 
  /// يتحقق من:
  /// - تفعيل المحفظة (wallet_enabled)
  /// - تفعيل التحويل (wallet_withdraw_market)
  /// - كفاية الرصيد
  Future<Map<String, dynamic>> transferToWallet(double amount) async {
    try {

      final response = await _apiClient.post(
        '/data/market/transfer',
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

  /// جلب إحصائيات الرصيد والمدفوعات
  /// 
  /// GET /data/market/stats
  /// 
  /// يرجع:
  /// - الرصيد الحالي
  /// - إجمالي المدفوعات (المقبول)
  /// - إجمالي المعلق (Pending)
  /// - إجمالي المكتسب (Earned)
  Future<Map<String, dynamic>> getStats() async {
    try {

      final response = await _apiClient.get(
        '/data/market/stats',
      );

      if (response['error'] == false && response['data'] != null) {
        final stats = MarketStats.fromJson(
          response['data'] is Map<String, dynamic>
              ? response['data']
              : <String, dynamic>{},
        );
        return {
          'success': true,
          'data': stats,
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load stats',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
