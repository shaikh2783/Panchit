import '../../../../core/network/api_client.dart';
import '../../../../main.dart' show configCfgP;
import '../models/models.dart';

/// Blog API Service
/// Wraps the endpoints documented in docs/blog/BLOG_API.md
class BlogApiService {
  final ApiClient _client;
  BlogApiService(this._client);

  Future<List<BlogCategory>> getCategories() async {
    final res = await _client.get(configCfgP('blogs_categories'));
    final list = (res['data']?['categories'] as List<dynamic>? ?? []);
    return list.map((e) => BlogCategory.fromJson(e)).toList();
  }

  Future<List<BlogPost>> getPosts({
    int? categoryId,
    String? search,
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get(configCfgP('blogs_posts'), queryParameters: query);
    final list = (res['data']?['posts'] as List<dynamic>? ?? []);
    return list.map((e) => BlogPost.fromJson(e)).toList();
  }

  Future<List<BlogPost>> getMyPosts({
    String? search,
    int offset = 0,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      'filter': 'my',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get(configCfgP('blogs_posts'), queryParameters: query);
    final list = (res['data']?['posts'] as List<dynamic>? ?? []);
    return list.map((e) => BlogPost.fromJson(e)).toList();
  }

  Future<BlogPost> getPost(int id) async {
    final res = await _client.get('${configCfgP('blogs_posts')}/$id');
    return BlogPost.fromJson(res['data']?['post'] as Map<String, dynamic>);
  }

  Future<BlogPost> createPost(Map<String, dynamic> body) async {
    final res = await _client.post(configCfgP('blogs_posts'), body: body);
    return BlogPost.fromJson(res['data']?['post'] as Map<String, dynamic>);
  }

  Future<BlogPost> updatePost(int id, Map<String, dynamic> body) async {
    // Some PHP backends reject PUT and 302-redirect; use POST to /update
    final res = await _client.post('${configCfgP('blogs_posts')}/$id', body: body);
    return BlogPost.fromJson(res['data']?['post'] as Map<String, dynamic>);
  }

  Future<bool> deletePost(int id) async {
    final res = await _client.post('${configCfgP('blogs_posts')}/$id', body: {});
    final data = res['data'] as Map<String, dynamic>?;
    if (data == null) return false;
    return (data['deleted'] == true) || (data['post_id'] == id);
  }
}
