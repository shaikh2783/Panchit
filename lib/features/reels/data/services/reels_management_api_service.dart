import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;

/// خدمة إدارة الريلز - تفاعل، حفظ، مشاهدة، إلخ
class ReelsManagementApiService {
  final ApiClient _apiClient;

  ReelsManagementApiService(this._apiClient);

  /// تفاعل مع الريل (إعجاب، حب، إلخ)
  Future<Map<String, dynamic>> reactToReel({
    required int reelId,
    required String reaction,
    required bool isReacting, // true للتفاعل، false لإلغاء التفاعل
  }) async {
    try {

      // تحويل 'remove' إلى منطق صحيح للـ API
      final apiReaction = reaction == 'remove' ? 'like' : reaction; // استخدام like كقيمة افتراضية عند الإزالة

      final response = await _apiClient.post(
        configCfgP('post_react'), // نفس API المنشورات
        body: {
          'post_id': reelId,
          'reaction': apiReaction,
          'react_type': isReacting ? 'react' : 'unreact', // هذا هو المهم!
        },
      );

      if (response['status'] == 'success') {
        return response;
      } else {
        throw ReelException(
          code: 400, 
          message: response['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// حفظ/إلغاء حفظ الريل
  Future<Map<String, dynamic>> manageReel({
    required int reelId,
    required String action, // save_post, unsave_post, etc.
  }) async {
    try {
      final response = await _apiClient.post(
        configCfgP('post_manage'), // نفس API إدارة المنشورات
        body: {
          'post_id': reelId,
          'action': action,
        },
      );

      if (response['status'] == 'success') {
        return response;
      } else {
        throw ReelException(
          code: 400, 
          message: response['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// إبلاغ عن مشاهدة الريل
  Future<void> recordView(int reelId) async {
    try {
      await _apiClient.post(
        configCfgP('reel_view'),
        body: {
          'reel_id': reelId,
        },
      );
    } catch (e) {
      // لا نرمي الخطأ لأن تسجيل المشاهدة ليس عملية حرجة
    }
  }
}

/// استثناء الريلز
class ReelException implements Exception {
  final int code;
  final String message;

  ReelException({required this.code, required this.message});

  @override
  String toString() => 'ReelException (code: $code): $message';
}
