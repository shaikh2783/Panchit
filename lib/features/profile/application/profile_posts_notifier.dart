import 'package:flutter/foundation.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';

/// Notifier منفصل لمنشورات الملف الشخصي
class ProfilePostsNotifier extends ChangeNotifier {
  ProfilePostsNotifier(this._postsApiService);

  final PostsApiService _postsApiService;

  final List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<Post> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  /// تحميل منشورات مستخدم محدد
  Future<void> loadUserPosts(String userId) async {
    if (_isLoading && _currentUserId == userId) return;

    _isLoading = true;
    _error = null;
    _currentUserId = userId;
    notifyListeners();

    try {
      final response = await _postsApiService.fetchUserPosts(
        userId: int.parse(userId),
        limit: 20,
        offset: 0,
      );

      _posts.clear();
      _posts.addAll(response.posts);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إضافة منشور جديد
  void addPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }

  /// تحديث منشور موجود
  void updatePost(Post updatedPost) {
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }

  /// حذف منشور
  void deletePost(int postId) {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  /// تحديث تفاعل منشور
  void updateReaction(String postId, String reaction) {
    final index = _posts.indexWhere((p) => p.id.toString() == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWithReaction(reaction);
      notifyListeners();
    }
  }

  /// تنظيف البيانات
  void clear() {
    _posts.clear();
    _currentUserId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}