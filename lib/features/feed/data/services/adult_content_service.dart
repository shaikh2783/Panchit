import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;

/// خدمة إدارة محتوى البالغين والـ Blur
class AdultContentService {
  final ApiClient _apiClient;

  AdultContentService(this._apiClient);

  /// تحديث blur لصورة واحدة
  /// POST /data/photos/blur
  Future<Map<String, dynamic>> updatePhotoBlur({
    required int photoId,
    required bool blur,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('photo_blur'),
        body: {
          'photo_id': photoId,
          'blur': blur ? 1 : 0,
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update photo blur');
      }

      return response;
    } catch (e) {

      rethrow;
    }
  }

  /// تطبيق blur على جميع صور المنشور
  /// POST /data/posts/blur
  Future<Map<String, dynamic>> applyBlurToPostPhotos({
    required int postId,
    required bool blur,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('post_blur'),
        body: {
          'post_id': postId,
          'blur': blur ? 1 : 0,
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to apply blur to post photos');
      }

      return response;
    } catch (e) {

      rethrow;
    }
  }

  /// تعليم المنشور كـ للبالغين وتطبيق blur تلقائياً
  /// POST /data/posts/adult
  Future<Map<String, dynamic>> markPostAsAdult({
    required int postId,
    required bool adult,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('post_adult'),
        body: {
          'post_id': postId,
          'adult': adult ? 1 : 0,
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to mark post as adult');
      }

      return response;
    } catch (e) {

      rethrow;
    }
  }

  /// تحديث حالة للبالغين للمنشور (بدون blur تلقائي)
  /// يستخدم عندما نريد فقط تغيير حالة for_adult بدون التأثير على الصور
  Future<Map<String, dynamic>> updatePostAdultStatus({
    required int postId,
    required bool forAdult,
  }) async {
    try {

      // يمكن استخدام post management API إذا كان متوفراً
      // أو إنشاء endpoint جديد
      final response = await _apiClient.post(
        configCfgP('post_manage'),
        body: {
          'post_id': postId,
          'action': 'adult_content',
          'value': forAdult ? 1 : 0,
        },
      );

      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to update adult status');
      }

      return response;
    } catch (e) {

      rethrow;
    }
  }
}
