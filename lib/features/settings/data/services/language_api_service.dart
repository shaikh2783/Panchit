import '../../../../core/network/api_client.dart';
import 'package:flutter/foundation.dart';

/// Language Settings API Service
/// خدمة تحديث لغة الحساب في السيرفر
class LanguageApiService {
  final ApiClient _apiClient;

  LanguageApiService(this._apiClient);

  /// تحديث لغة الحساب
  /// POST /data/settings/language
  /// 
  /// Parameters:
  /// - [languageCode]: كود اللغة مثل "en_us", "ar_ar", "fr_fr"
  /// - [languageId]: ID اللغة (اختياري)
  /// 
  /// Response:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "message": "Language updated successfully",
  ///   "data": {
  ///     "language": {
  ///       "language_id": 2,
  ///       "code": "ar_ar",
  ///       "title": "العربية",
  ///       "title_native": "Arabic",
  ///       "flag": "https://example.com/flags/ar.png",
  ///       "dir": "rtl"
  ///     }
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> updateLanguage({
    String? languageCode,
    int? languageId,
  }) async {
    try {

      final body = <String, dynamic>{};
      
      if (languageCode != null) {
        // تحويل الكود إلى الصيغة المطلوبة (مثل en_US -> en_us)
        body['language_code'] = languageCode.toLowerCase();
      }
      
      if (languageId != null) {
        body['language_id'] = languageId;
      }

      final response = await _apiClient.post(
        '/data/settings/language',
        body: body,
      );

      final status = response['status'];
      final isSuccess = status == 'success' || response['error'] != true;

      if (isSuccess) {
        return {
          'success': true,
          'message': response['message'] ?? 'Language updated successfully',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to update language',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// جلب قائمة اللغات المتاحة من السيرفر
  /// GET /data/languages
  Future<Map<String, dynamic>> getAvailableLanguages() async {
    try {

      final response = await _apiClient.get('/data/languages');

      final isError = response['error'] == true;
      if (!isError && response['data'] != null) {
        return {
          'success': true,
          'languages': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch languages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}