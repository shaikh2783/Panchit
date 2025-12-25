import 'package:snginepro/core/network/api_client.dart';

class BoostApiService {
  final ApiClient _client;

  BoostApiService(this._client);

  // ==================== Posts Boost ====================

  /// تعزيز منشور
  Future<Map<String, dynamic>> boostPost(int postId) async {
    return await _client.post(
      '/data/posts/$postId/boost',
      body: {'post_id': postId},
    );
  }

  /// إلغاء تعزيز منشور  
  Future<Map<String, dynamic>> unboostPost(int postId) async {
    return await _client.post(
      '/data/posts/$postId/unboost',
      body: {'post_id': postId},
    );
  }

  /// عرض المنشورات المعززة
  Future<Map<String, dynamic>> getBoostedPosts({
    int offset = 0,
    int limit = 10,
  }) async {
    return await _client.get(
      '/data/boosted-posts',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );
  }

  // ==================== Pages Boost ====================

  /// تعزيز صفحة
  Future<Map<String, dynamic>> boostPage(int pageId) async {
    return await _client.post(
      '/data/pages/$pageId/boost',
      body: {'page_id': pageId},
    );
  }

  /// إلغاء تعزيز صفحة
  Future<Map<String, dynamic>> unboostPage(int pageId) async {
    return await _client.post(
      '/data/pages/$pageId/unboost',
      body: {'page_id': pageId},
    );
  }

  /// عرض الصفحات المعززة
  Future<Map<String, dynamic>> getBoostedPages({
    int offset = 0,
    int limit = 10,
  }) async {
    return await _client.get(
      '/data/boosted-pages',
      queryParameters: {
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );
  }
}
