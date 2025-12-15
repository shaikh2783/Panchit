import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/stories/data/models/stories_response.dart';
class StoriesApiService {
  StoriesApiService(this._client);
  final ApiClient _client;
  /// Fetch stories with optional format parameter
  /// format: 'both' | 'user' | 'others'
  /// - both: Get user's own stories and friends' stories
  /// - user: Get only user's own stories
  /// - others: Get only friends' stories
  Future<StoriesResponse> fetchStories({
    String format = 'both',
  }) async {
    final response = await _client.get(
      configCfgP('stories'),
      queryParameters: {
        'format': format,
      },
    );
    final storiesResponse = StoriesResponse.fromJson(response);
    if (!storiesResponse.isSuccess) {
      throw ApiException(
        storiesResponse.message ?? 'فشل في جلب القصص',
        details: response,
      );
    }
    return storiesResponse;
  }
  /// Create a new story with photo or video
  Future<Map<String, dynamic>> createStory({
    String? imagePath,
    String? videoPath,
    String? text,
  }) async {
    try {
      final fields = <String, String>{};
      if (text != null && text.isNotEmpty) {
        fields['text'] = text;
      }
      // استخدام multipartPost لرفع ملف واحد
      if (imagePath != null) {
        final response = await _client.multipartPost(
          configCfgP('stories'),
          body: fields,
          filePath: imagePath,
          fileFieldName: 'photo',
        );
        // التحقق من النجاح: status == "success" أو api_status == 200
        final isSuccess = response['status'] == 'success' || 
                         response['api_status'] == 200 ||
                         response['code'] == 200;
        if (!isSuccess) {
          throw ApiException(
            response['message'] ?? 'فشل في إنشاء القصة',
            details: response,
          );
        }
        return response;
      }
      if (videoPath != null) {
        final response = await _client.multipartPost(
          configCfgP('stories'),
          body: fields,
          filePath: videoPath,
          fileFieldName: 'video',
        );
        // التحقق من النجاح: status == "success" أو api_status == 200
        final isSuccess = response['status'] == 'success' || 
                         response['api_status'] == 200 ||
                         response['code'] == 200;
        if (!isSuccess) {
          throw ApiException(
            response['message'] ?? 'فشل في إنشاء القصة',
            details: response,
          );
        }
        return response;
      }
      // إذا لم يكن هناك ملف، نرسل فقط النص
      final response = await _client.post(
        configCfgP('stories'),
        body: fields,
      );
      // التحقق من النجاح: status == "success" أو api_status == 200
      final isSuccess = response['status'] == 'success' || 
                       response['api_status'] == 200 ||
                       response['code'] == 200;
      if (!isSuccess) {
        throw ApiException(
          response['message'] ?? 'فشل في إنشاء القصة',
          details: response,
        );
      }
      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('خطأ في إنشاء القصة: $e');
    }
  }
}
