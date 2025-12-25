import '../../../../core/network/api_client.dart';
import '../models/bank_settings.dart';
import '../models/bank_transfer.dart';

/// Bank API Service
/// خدمة API للتحويلات البنكية وإعدادات البنك

class BankApiService {
  final ApiClient _apiClient;

  BankApiService(this._apiClient);

  /// جلب إعدادات الحساب البنكي
  /// 
  /// GET /data/bank/settings
  /// 
  /// يرجع:
  /// - بيانات الحساب البنكي
  /// - تعليمات التحويل
  /// - ما إذا كان التحويل مفعل
  Future<Map<String, dynamic>> getSettings() async {
    try {

      final response = await _apiClient.get(
        '/data/bank/settings',
      );

      if (response['error'] == false && response['data'] != null) {
        final settings = BankSettings.fromJson(
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
        'message': response['message'] ?? 'Failed to load bank settings',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// جلب سجل التحويلات البنكية
  /// 
  /// GET /data/bank/transfers
  /// 
  /// يرجع:
  /// - قائمة جميع التحويلات البنكية للمستخدم
  /// - حالة كل تحويل
  /// - تفاصيل العملية المرتبطة بالتحويل
  Future<Map<String, dynamic>> getTransfers() async {
    try {

      final response = await _apiClient.get(
        '/data/bank/transfers',
      );

      if (response['error'] == false && response['data'] != null) {
        final transfers = <BankTransfer>[];

        if (response['data'] is List) {
          for (final item in response['data']) {
            if (item is Map<String, dynamic>) {
              transfers.add(BankTransfer.fromJson(item));
            }
          }
        }

        return {
          'success': true,
          'data': transfers,
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to load transfers',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
