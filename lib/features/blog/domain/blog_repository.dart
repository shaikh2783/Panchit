import '../data/models/models.dart';
import '../data/services/blog_api_service.dart';
/// Blog Repository: thin wrapper around BlogApiService for consistency
class BlogRepository {
  final BlogApiService _api;
  BlogRepository(this._api);
  Future<List<BlogCategory>> getCategories() => _api.getCategories();
  Future<List<BlogPost>> getPosts({
    int? categoryId,
    String? search,
    int offset = 0,
    int limit = 20,
  }) {
    return _api.getPosts(
      categoryId: categoryId,
      search: search,
      offset: offset,
      limit: limit,
    );
  }
  Future<List<BlogPost>> getMyPosts({
    String? search,
    int offset = 0,
    int limit = 20,
  }) {
    return _api.getMyPosts(
      search: search,
      offset: offset,
      limit: limit,
    );
  }
  Future<BlogPost> getPost(int id) => _api.getPost(id);
  Future<BlogPost> createPost(Map<String, dynamic> body) => _api.createPost(body);
  Future<BlogPost> updatePost(int id, Map<String, dynamic> body) => _api.updatePost(id, body);
  Future<bool> deletePost(int id) => _api.deletePost(id);
}
