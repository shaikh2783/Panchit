import '../data/services/share_api_service.dart';

/// Repository لإدارة عمليات المشاركة
class ShareRepository {
  final ShareApiService _apiService;

  ShareRepository(this._apiService);

  /// مشاركة منشور على Timeline
  Future<Map<String, dynamic>> shareToTimeline({
    required int postId,
    String? message,
  }) async {
    return await _apiService.sharePost(
      postId: postId,
      message: message,
      shareTo: 'timeline',
    );
  }

  /// مشاركة منشور على صفحة
  Future<Map<String, dynamic>> shareToPage({
    required int postId,
    required int pageId,
    String? message,
  }) async {
    return await _apiService.sharePost(
      postId: postId,
      message: message,
      shareTo: 'page',
      pageId: pageId,
    );
  }

  /// مشاركة منشور في مجموعة
  Future<Map<String, dynamic>> shareToGroup({
    required int postId,
    required int groupId,
    String? message,
  }) async {
    return await _apiService.sharePost(
      postId: postId,
      message: message,
      shareTo: 'group',
      groupId: groupId,
    );
  }

  /// مشاركة منشور في حدث
  Future<Map<String, dynamic>> shareToEvent({
    required int postId,
    required int eventId,
    String? message,
  }) async {
    return await _apiService.sharePost(
      postId: postId,
      message: message,
      shareTo: 'event',
      eventId: eventId,
    );
  }

  /// الحصول على قائمة الصفحات التي يمكن المشاركة عليها
  Future<List<Map<String, dynamic>>> getShareablePages() async {
    return await _apiService.getShareablePages();
  }

  /// الحصول على قائمة المجموعات التي يمكن المشاركة فيها
  Future<List<Map<String, dynamic>>> getShareableGroups() async {
    return await _apiService.getShareableGroups();
  }

  /// الحصول على قائمة الأحداث التي يمكن المشاركة فيها
  Future<List<Map<String, dynamic>>> getShareableEvents() async {
    return await _apiService.getShareableEvents();
  }
}
