import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/feed/application/bloc/posts_events.dart';
import 'package:snginepro/features/feed/domain/posts_repository.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsRepository _repository;
  final int _pageSize = 10;
  int _currentPage = 0; // متتبع الصفحة الحالية
  PostsBloc(this._repository) : super(PostsInitialState()) {
    on<LoadPostsEvent>(_onLoadPosts);
    on<RefreshPostsEvent>(_onRefreshPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
    on<AddPostEvent>(_onAddPost);
    on<UpdatePostEvent>(_onUpdatePost);
    on<DeletePostEvent>(_onDeletePost);
    on<ReactToPostEvent>(_onReactToPost);
    on<LoadPromotedPostEvent>(_onLoadPromotedPost);
  }
  Future<void> _onLoadPosts(LoadPostsEvent event, Emitter<PostsState> emit) async {
    emit(PostsLoadingState());
    try {
      _currentPage = 0; // إعادة تعيين الصفحة
      final response = await _repository.fetchNewsfeed(
        limit: _pageSize,
        offset: 0,
      );
      // Debug: Show all received post IDs
      if (response.posts.isNotEmpty) {
        for (int i = 0; i < response.posts.length; i++) {
          final post = response.posts[i];
        }
        // Check if Post ID 0 is in initial load
        final hasPostZero = response.posts.any((p) => p.id == 0);
      } else {
      }
      emit(PostsLoadedState(
        posts: response.posts,
        hasMore: response.hasMore,
      ));
    } catch (e) {
      emit(PostsErrorState(e.toString()));
    }
  }
  Future<void> _onRefreshPosts(RefreshPostsEvent event, Emitter<PostsState> emit) async {
    try {
      _currentPage = 0; // إعادة تعيين الصفحة
      final response = await _repository.fetchNewsfeed(
        limit: _pageSize,
        offset: 0,
      );
      emit(PostsLoadedState(
        posts: response.posts,
        hasMore: response.hasMore,
      ));
    } catch (e) {
      // Preserve the current state if refresh fails
      if (state is PostsLoadedState) {
        final currentState = state as PostsLoadedState;
        emit(currentState.copyWith(isLoadingMore: false));
      } else {
        emit(PostsErrorState(e.toString()));
      }
    }
  }
  Future<void> _onLoadMorePosts(LoadMorePostsEvent event, Emitter<PostsState> emit) async {
    if (state is! PostsLoadedState) return;
    final currentState = state as PostsLoadedState;
    if (!currentState.hasMore || currentState.isLoadingMore) {
      return;
    }
    emit(currentState.copyWith(isLoadingMore: true));
    try {
      _currentPage++; // زيادة رقم الصفحة
      final response = await _repository.fetchNewsfeed(
        limit: _pageSize,
        offset: _currentPage, // استخدام رقم الصفحة مباشرة (0, 1, 2, 3...)
      );
      // تجنب المنشورات المكررة (لكن نسمح بتكرار الإعلانات)
      final currentPostIds = currentState.posts.map((p) => p.id).toSet();
      final uniqueNewPosts = response.posts.where((post) {
        // السماح بجميع الإعلانات حتى لو كان لها نفس الـ ID
        if (post.isAd) return true;
        // تصفية المنشورات العادية المكررة فقط
        return !currentPostIds.contains(post.id);
      }).toList();
      final newPosts = List<Post>.from(currentState.posts)..addAll(uniqueNewPosts);
      emit(PostsLoadedState(
        posts: newPosts,
        hasMore: response.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      _currentPage--; // التراجع عن زيادة الصفحة في حالة الخطأ
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
  void _onAddPost(AddPostEvent event, Emitter<PostsState> emit) {
    if (state is PostsLoadedState) {
      final currentState = state as PostsLoadedState;
      final newPosts = List<Post>.from([event.post])..addAll(currentState.posts);
      emit(currentState.copyWith(posts: newPosts));
    }
  }
  void _onUpdatePost(UpdatePostEvent event, Emitter<PostsState> emit) {
    if (state is PostsLoadedState) {
      final currentState = state as PostsLoadedState;
      final newPosts = currentState.posts.map((post) {
        return post.id == event.post.id ? event.post : post;
      }).toList();
      emit(currentState.copyWith(posts: newPosts));
    }
  }
  void _onDeletePost(DeletePostEvent event, Emitter<PostsState> emit) {
    if (state is PostsLoadedState) {
      final currentState = state as PostsLoadedState;
      final newPosts = currentState.posts.where((post) => post.id != event.postId).toList();
      emit(currentState.copyWith(posts: newPosts));
    }
  }
  Future<void> _onReactToPost(ReactToPostEvent event, Emitter<PostsState> emit) async {
    if (state is PostsLoadedState) {
      final currentState = state as PostsLoadedState;
      // Debug: Log current post position
      final postIndex = currentState.posts.indexWhere((post) => post.id == event.postId);
      // تحويل 'remove' إلى null للـ optimistic update
      final reactionForUpdate = event.reaction == 'remove' ? null : event.reaction;
      // Optimistic update - maintain order
      final newPosts = currentState.posts.map((post) {
        if (post.id == event.postId) {
          final updatedPost = post.copyWithReaction(reactionForUpdate);
          return updatedPost;
        }
        return post;
      }).toList();
      // Verify order is preserved
      final newPostIndex = newPosts.indexWhere((post) => post.id == event.postId);
      emit(currentState.copyWith(posts: newPosts));
      try {
        await _repository.reactToPost(event.postId, event.reaction);
      } catch (e) {
        // Revert on error
        emit(currentState);
      }
    }
  }
  Future<void> _onLoadPromotedPost(LoadPromotedPostEvent event, Emitter<PostsState> emit) async {
    try {
      // Here you can add logic to fetch a promoted post
      // For now, we'll just print a message since the promoted post functionality
      // might not be fully implemented yet
      // If you have an API call for promoted posts, add it here:
      // final promotedPost = await _repository.fetchPromotedPost();
      // emit(state.copyWith(promotedPost: promotedPost));
    } catch (e) {
    }
  }
}