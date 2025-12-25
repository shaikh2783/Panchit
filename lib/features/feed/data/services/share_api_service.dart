import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;

/// خدمة API لمشاركة المنشورات
class ShareApiService {
  final ApiClient _apiClient;

  ShareApiService(this._apiClient);

  /// مشاركة منشور على Timeline أو صفحة أو مجموعة أو حدث
  /// 
  /// [postId] - معرف المنشور المراد مشاركته
  /// [message] - نص إضافي مع المشاركة (اختياري)
  /// [shareTo] - نوع المشاركة: timeline, page, group, event
  /// [pageId] - معرف الصفحة (مطلوب عند shareTo = page)
  /// [groupId] - معرف المجموعة (مطلوب عند shareTo = group)
  /// [eventId] - معرف الحدث (مطلوب عند shareTo = event)
  Future<Map<String, dynamic>> sharePost({
    required int postId,
    String? message,
    required String shareTo,
    int? pageId,
    int? groupId,
    int? eventId,
  }) async {
    try {

      // بناء body الطلب
      final body = <String, dynamic>{
        'post_id': postId,
        'share_to': shareTo,
      };

      // إضافة الرسالة إن وجدت
      if (message != null && message.isNotEmpty) {
        body['message'] = message;
      }

      // إضافة المعرفات حسب نوع المشاركة
      switch (shareTo) {
        case 'page':
          if (pageId == null) {
            throw Exception('page_id is required when share_to is "page"');
          }
          body['page_id'] = pageId;
          break;
        case 'group':
          if (groupId == null) {
            throw Exception('group_id is required when share_to is "group"');
          }
          body['group_id'] = groupId;
          break;
        case 'event':
          if (eventId == null) {
            throw Exception('event_id is required when share_to is "event"');
          }
          body['event_id'] = eventId;
          break;
        case 'timeline':
          // لا يتطلب معرفات إضافية
          break;
        default:
          throw Exception('Invalid share_to value: $shareTo');
      }


      final response = await _apiClient.post(
        configCfgP('posts_share'),
        body: body,
      );


      if (response['status'] == 'success' || response['error'] == false) {
        return {
          'success': true,
          'message': response['message'] ?? 'تم مشاركة المنشور بنجاح',
          'data': response['data'],
        };
      } else {
        throw Exception(
          response['message'] ?? 'فشل في مشاركة المنشور',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// الحصول على قائمة الصفحات التي يمكن المشاركة عليها
  Future<List<Map<String, dynamic>>> getShareablePages() async {
    try {

      final response = await _apiClient.get(
        configCfgP('pages_my'),
      );

      if (response['status'] == 'success' || response['error'] == false) {
        final pages = response['data'] as List?;
        if (pages != null) {
          return pages.map((page) => page as Map<String, dynamic>).toList();
        }
        return [];
      } else {
        throw Exception('فشل في جلب الصفحات');
      }
    } catch (e) {
      return [];
    }
  }

  /// الحصول على قائمة المجموعات التي يمكن المشاركة فيها
  Future<List<Map<String, dynamic>>> getShareableGroups() async {
    try {

      final response = await _apiClient.get(
        configCfgP('user_groups'),
        queryParameters: {
          'status': 'approved',
        },
      );

      if (response['status'] == 'success' || response['error'] == false) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null && data.containsKey('groups')) {
          final groups = data['groups'] as List?;
          if (groups != null) {
            return groups.map((group) => group as Map<String, dynamic>).toList();
          }
        }
        return [];
      } else {
        throw Exception('فشل في جلب المجموعات');
      }
    } catch (e) {
      return [];
    }
  }

  /// الحصول على قائمة الأحداث التي يمكن المشاركة فيها
  Future<List<Map<String, dynamic>>> getShareableEvents() async {
    try {

      final response = await _apiClient.get(
        configCfgP('events_my'),
      );

      if (response['status'] == 'success' || response['error'] == false) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null && data.containsKey('results')) {
          final events = data['results'] as List?;
          if (events != null) {
            return events.map((event) => event as Map<String, dynamic>).toList();
          }
        }
        return [];
      } else {
        throw Exception('فشل في جلب الأحداث');
      }
    } catch (e) {
      return [];
    }
  }
}
