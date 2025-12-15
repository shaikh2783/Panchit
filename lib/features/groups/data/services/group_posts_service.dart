import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../../../feed/data/models/post.dart';
/// خدمة جلب منشورات المجموعة
class GroupPostsService {
  final ApiClient _apiClient;
  GroupPostsService(this._apiClient);
  /// جلب منشورات المجموعة
  Future<List<Post>> getGroupPosts({
    required int groupId,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('groups_posts'),
        queryParameters: {
          'group_id': groupId.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> postsJson = response['data']['posts'] ?? [];
        final posts = postsJson.map((json) => Post.fromJson(json)).toList();
        return posts;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  /// تحقق من وجود المزيد من المنشورات
  Future<bool> hasMorePosts({
    required int groupId,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('groups_posts'),
        queryParameters: {
          'group_id': groupId.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      return response['has_more'] == true;
    } catch (e) {
      return false;
    }
  }
}
