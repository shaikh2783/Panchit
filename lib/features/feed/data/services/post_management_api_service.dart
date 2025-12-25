import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;

/// خدمة إدارة المنشورات - حفظ، تثبيت، إخفاء، حذف، تفاعل، تعديل
class PostManagementApiService {
  final ApiClient _apiClient;

  PostManagementApiService(this._apiClient);

  /// إجراءات إدارة المنشورات
  Future<Map<String, dynamic>> managePost({
    required int postId,
    required PostAction action,
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('post_manage'),
        body: {
          'post_id': postId,
          'action': action.value,
        },
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400, 
          message: response['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// تفاعل مع المنشور (إعجاب، حب، إلخ)
  Future<Map<String, dynamic>> reactToPost({
    required int postId,
    required String reaction,
    required bool isReacting, // true للتفاعل، false لإلغاء التفاعل
  }) async {
    try {

      final response = await _apiClient.post(
        configCfgP('post_react'),
        body: {
          'post_id': postId,
          'reaction': reaction,
          'react_type': isReacting ? 'react' : 'unreact',
        },
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400, 
          message: response['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// تعديل المنشور
  Future<Map<String, dynamic>> editPost({
    required int postId,
    String? text,
    String? privacy,
    String? location,
  }) async {
    try {
      
      final body = <String, dynamic>{
        'post_id': postId,
      };
      
      if (text != null) body['text'] = text;
      if (privacy != null) body['privacy'] = privacy;
      if (location != null) body['location'] = location;
      

      final response = await _apiClient.post(
        configCfgP('post_edit'),
        body: body,
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400, 
          message: response['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// الحصول على تفاصيل المنشور
  Future<Map<String, dynamic>> getPostDetails(int postId) async {
    try {

      final response = await _apiClient.get(
        configCfgP('post_details'),
        queryParameters: {
          'post_id': postId.toString(),
        },
      );


      if (response['status'] == 'success') {
        return response;
      } else {
        throw ApiException(
          code: 400, 
          message: response['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// أنواع الإجراءات المتاحة للمنشورات
enum PostAction {
  savePost('save_post'),
  unsavePost('unsave_post'),
  pinPost('pin_post'),
  unpinPost('unpin_post'),
  hidePost('hide_post'),
  unhidePost('unhide_post'),
  deletePost('delete_post'),
  editPost('edit_post'),  // 🆕 إضافة تعديل المنشور
  boostPost('boost_post'),
  unboostPost('unboost_post'),
  monetizePost('monetize_post'),
  unmonetizePost('unmonetize_post'),
  disableComments('disable_comments'),
  enableComments('enable_comments'),
  soldPost('sold_post'),
  unsoldPost('unsold_post'),
  closedPost('closed_post'),
  unclosedPost('unclosed_post'),
  allowPost('allow_post'),
  disallowPost('disallow_post'),
  markAsAdult('mark_as_adult'),  // 🆕 تعليم المنشور كـ للبالغين + blur
  unmarkAsAdult('unmark_as_adult');  // 🆕 إلغاء تعليم المنشور كـ للبالغين

  const PostAction(this.value);
  final String value;
}

/// استثناء API
class ApiException implements Exception {
  final int code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => 'ApiException (code: $code): $message';
}
