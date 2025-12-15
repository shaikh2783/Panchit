import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/data/models/story.dart';
import 'package:snginepro/features/feed/domain/posts_repository.dart';
class PostsNotifier extends ChangeNotifier {
  PostsNotifier(this._repository);
  final PostsRepository _repository;
  final List<Post> _posts = [];
  final List<Story> _stories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = false;
  String? _error;
  int _page = 0;
  final int _limit = 10;
  List<Post> get posts => List.unmodifiable(_posts);
  List<Story> get stories => List.unmodifiable(_stories);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  Future<void> loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        loadStories(),
        loadInitialPosts(),
      ]);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'تعذر تحميل المنشورات، يرجى المحاولة لاحقاً.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> loadStories() async {
    final response = await _repository.fetchStories();
    _stories
      ..clear()
      ..addAll(response);
  }
  Future<void> loadInitialPosts() async {
    final response = await _repository.fetchNewsfeed(
      limit: _limit,
      offset: 0,
    );
    _posts
      ..clear()
      ..addAll(response.posts);
    _page = 1;
    _hasMore = response.hasMore;
  }
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        loadStories(),
        loadInitialPosts(),
      ]);
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'حدث خطأ أثناء التحديث.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _repository.fetchNewsfeed(
        limit: _limit,
        offset: _page,
      );
      _posts.addAll(response.posts);
      if (response.posts.isNotEmpty) {
        _page += 1;
      }
      _hasMore = response.hasMore;
    } on ApiException catch (error) {
      _error = error.message;
    } catch (error) {
      _error = 'حدث خطأ أثناء جلب المزيد من المنشورات.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  Future<void> setReaction(int postId, String reaction) async {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    final oldPost = _posts[postIndex];
    final oldReaction = oldPost.myReaction;
    final String reactionToSend = (oldReaction == reaction) ? 'remove' : reaction;
    int newReactionsCount = oldPost.reactionsCount;
    if (reactionToSend == 'remove') {
      if(oldReaction != null) newReactionsCount--;
    } else {
      if(oldReaction == null) newReactionsCount++;
    }
    final newPost = oldPost.copyWith(
      myReaction: reactionToSend == 'remove' ? null : reactionToSend,
      clearMyReaction: reactionToSend == 'remove',
      reactionsCount: newReactionsCount,
    );
    _posts[postIndex] = newPost;
    notifyListeners();
    try {
      await _repository.reactToPost(postId, reactionToSend);
    } on ApiException catch (e) {
      _error = e.message;
      _posts[postIndex] = oldPost;
      notifyListeners();
    }
  }
  Future<void> createPost(
    String message, {
    List<File>? photos,
    int? coloredPattern,
    String? feelingAction,
    String? feelingValue,
  }) async {
    List<String>? photoSources;
    if (photos != null && photos.isNotEmpty) {
      final sources = await Future.wait(
        photos.map((photo) => _repository.uploadPhoto(photo)),
      );
      photoSources = sources.whereType<String>().toList();
    }
    await _repository.createPost(
      message,
      photoSources: photoSources,
      coloredPattern: coloredPattern,
      feelingAction: feelingAction,
      feelingValue: feelingValue,
    );
    // إعادة تحميل الصفحة الأولى فقط للحصول على المنشور الجديد
    await refresh();
  }
  /// إضافة منشور جديد إلى بداية القائمة
  void addPost(Post newPost) {
    _posts.insert(0, newPost);
    notifyListeners();
  }
  /// تحديث منشور موجود
  void updatePost(Post updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }
  /// حذف منشور من القائمة
  void deletePost(int postId) {
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();
  }
  void clear() {
    _posts.clear();
    _stories.clear();
    _page = 0;
    _hasMore = false;
    _isLoading = false;
    _isLoadingMore = false;
    _isRefreshing = false;
    _error = null;
    notifyListeners();
  }
}
