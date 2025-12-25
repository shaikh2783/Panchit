import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/report_reason.dart';

/// خدمة API للإبلاغ عن المحتوى
class ReportsApiService {
  final ApiClient _apiClient;

  ReportsApiService(this._apiClient);

  /// الإبلاغ عن منشور
  Future<Map<String, dynamic>> reportPost({
    required int postId,
    required int categoryId,
    String? reason,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('post_report'),
        body: {
          'post_id': postId,
          'category_id': categoryId,
          if (reason != null && reason.isNotEmpty)
            'reason': reason,
        },
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400,
          message: response['message'] ?? 'Failed to submit report'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// الحصول على فئات الإبلاغ
  Future<List<ReportCategoryModel>> getReportCategories() async {
    try {

      final response = await _apiClient.get(configCfgP('report_categories'));


      if (response['status'] == 'success') {
        final categoriesData = response['data'] as List?;
        if (categoriesData != null) {
          return categoriesData
            .map((category) => ReportCategoryModel.fromJson(category))
            .toList();
        }
        return [];
      } else {
        throw ApiException(
          code: 400,
          message: response['message'] ?? 'Failed to fetch categories'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// الإبلاغ عن مستخدم
  Future<Map<String, dynamic>> reportUser({
    required String userId,
    required String reasonId,
    String? additionalMessage,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('user_report'),
        body: {
          'user_id': userId,
          'reason': reasonId,
          if (additionalMessage != null && additionalMessage.isNotEmpty)
            'message': additionalMessage,
        },
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400,
          message: response['message'] ?? 'Failed to submit report'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// الإبلاغ عن تعليق
  Future<Map<String, dynamic>> reportComment({
    required int commentId,
    required String reasonId,
    String? additionalMessage,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('comment_report'),
        body: {
          'comment_id': commentId,
          'reason': reasonId,
          if (additionalMessage != null && additionalMessage.isNotEmpty)
            'message': additionalMessage,
        },
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400,
          message: response['message'] ?? 'Failed to submit report'
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// استثناء API
class ApiException implements Exception {
  final int code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => 'ApiException (code: $code): $message';
}
