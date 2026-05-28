import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/merits/data/models/merit_models.dart';
import 'package:flutter/foundation.dart';

/// خدمة API الجدارات
class MeritsApiService {
  final ApiClient _apiClient;

  MeritsApiService(this._apiClient);

  /// الحصول على رصيد الجدارة الحالي للمستخدم
  Future<MeritBalance?> getMeritsBalance() async {
    try {
      final response = await _apiClient.get('/data/merits/balance');

      if (response.containsKey('data')) {
        final data = response['data'];
        return MeritBalance.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// الحصول على فئات الجدارة المتاحة
  Future<List<MeritCategory>> getMeritsCategories() async {
    try {
      final response = await _apiClient.get('/data/merits/categories');

      if (response.containsKey('data') && response['data'] is List) {
        final categories = (response['data'] as List)
            .map((item) => MeritCategory.fromJson(item as Map<String, dynamic>))
            .toList();
        return categories;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// إرسال جدارة إلى مستقبلين
  Future<Map<String, dynamic>> sendMerit({
    required List<MeritRecipient> recipients,
    required int categoryId,
    required String message,
    String? image,
  }) async {
    try {
      final request = SendMeritRequest(
        recipients: recipients,
        categoryId: categoryId,
        message: message,
        image: image,
      );

      final response = await _apiClient.post(
        '/data/merits/send',
        body: request.toJson(),
      );

      return {
        'success': true,
        'message': response['message'] ?? 'تم إرسال الجدارة بنجاح',
        'recipientsCount': response['data']?['recipients_count'] ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e.toString()),
      };
    }
  }

  /// الحصول على أفضل المستخدمين في فئات الجدارات
  Future<List<TopMeritUser>> getTopMeritUsers() async {
    try {
      final response = await _apiClient.get('/data/merits/top-users');

      if (response.containsKey('data') && response['data'] is List) {
        final topUsers = (response['data'] as List)
            .map((item) => TopMeritUser.fromJson(item as Map<String, dynamic>))
            .toList();
        return topUsers;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// استخراج رسالة الخطأ من استثناء API
  String _extractErrorMessage(String error) {
    if (error.contains('You must select recipients')) {
      return 'يجب تحديد المستقبلين';
    } else if (error.contains('You must select a category')) {
      return 'يجب تحديد الفئة';
    } else if (error.contains("You can't send merits to yourself")) {
      return 'لا يمكن إرسال جدارة لنفسك';
    } else if (error.contains("You don't have enough merits")) {
      return 'ليس لديك جدارات كافية';
    } else if (error.contains('demo account')) {
      return 'لا يمكنك القيام بهذا من حساب تجريبي';
    } else if (error.contains('not logged in')) {
      return 'يجب تسجيل الدخول أولاً';
    } else if (error.contains('disabled')) {
      return 'نظام الجدارات معطل حالياً';
    }
    return 'حدث خطأ أثناء إرسال الجدارة';
  }
}