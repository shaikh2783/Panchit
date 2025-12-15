import 'package:flutter/foundation.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';
/// Notifier منفصل لمنشورات الصفحات
class PagesPostsNotifier extends ChangeNotifier {
  PagesPostsNotifier(this._pagesRepository);
  final PagesRepository _pagesRepository;
  final List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  int? _currentPageId;
  List<Post> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentPageId => _currentPageId;
  /// تحميل منشورات صفحة محددة
  Future<void> loadPagePosts(int pageId) async {
    if (_isLoading && _currentPageId == pageId) return;
    _isLoading = true;
    _error = null;
    _currentPageId = pageId;
    notifyListeners();
    try {
      final postsResponse = await _pagesRepository.fetchPagePosts(
        pageId: pageId.toString(),
        limit: 20,
        offset: 0,
      );
      final posts = postsResponse.posts;
      _posts.clear();
      _posts.addAll(posts);
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
    _currentPageId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}