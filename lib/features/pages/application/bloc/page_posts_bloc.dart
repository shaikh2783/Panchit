import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/pages/domain/pages_repository.dart';

// Events
abstract class PagePostsEvent {}

class LoadPagePostsEvent extends PagePostsEvent {
  final String pageId;
  LoadPagePostsEvent(this.pageId);
}

class LoadMorePagePostsEvent extends PagePostsEvent {
  LoadMorePagePostsEvent();
}

class RefreshPagePostsEvent extends PagePostsEvent {
  final String pageId;
  RefreshPagePostsEvent(this.pageId);
}

class AddPostToPageEvent extends PagePostsEvent {
  final Post post;
  AddPostToPageEvent(this.post);
}

class UpdatePostInPageEvent extends PagePostsEvent {
  final Post post;
  UpdatePostInPageEvent(this.post);
}

class DeletePostFromPageEvent extends PagePostsEvent {
  final int postId;
  DeletePostFromPageEvent(this.postId);
}

class ReactToPostInPageEvent extends PagePostsEvent {
  final int postId;
  final String reaction;
  ReactToPostInPageEvent(this.postId, this.reaction);
}

// States
abstract class PagePostsState {}

class PagePostsInitialState extends PagePostsState {}

class PagePostsLoadingState extends PagePostsState {}

class PagePostsLoadedState extends PagePostsState {
  final List<Post> posts;
  final String pageId;
  final bool hasMore;
  final bool isLoadingMore;

  PagePostsLoadedState({
    required this.posts,
    required this.pageId,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  PagePostsLoadedState copyWith({
    List<Post>? posts,
    String? pageId,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PagePostsLoadedState(
      posts: posts ?? this.posts,
      pageId: pageId ?? this.pageId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PagePostsErrorState extends PagePostsState {
  final String message;
  PagePostsErrorState(this.message);
}

// Bloc
class PagePostsBloc extends Bloc<PagePostsEvent, PagePostsState> {
  final PagesRepository _repository;
  final int _pageSize = 20;
  int _currentPage = 0; // متتبع الصفحة الحالية
  String? _currentPageId; // متتبع معرف الصفحة الحالية

  PagePostsBloc(this._repository) : super(PagePostsInitialState()) {
    on<LoadPagePostsEvent>(_onLoadPagePosts);
    on<LoadMorePagePostsEvent>(_onLoadMorePagePosts);
    on<RefreshPagePostsEvent>(_onRefreshPagePosts);
    on<AddPostToPageEvent>(_onAddPostToPage);
    on<UpdatePostInPageEvent>(_onUpdatePostInPage);
    on<DeletePostFromPageEvent>(_onDeletePostFromPage);
    on<ReactToPostInPageEvent>(_onReactToPostInPage);
  }

  Future<void> _onLoadPagePosts(LoadPagePostsEvent event, Emitter<PagePostsState> emit) async {
    emit(PagePostsLoadingState());
    
    try {

      _currentPage = 0; // إعادة تعيين الصفحة
      _currentPageId = event.pageId; // حفظ معرف الصفحة الحالية
      
      final response = await _repository.fetchPagePosts(
        pageId: event.pageId,
        limit: _pageSize,
        offset: _currentPage,
      );

      emit(PagePostsLoadedState(
        posts: response.posts,
        pageId: event.pageId,
        hasMore: response.hasMore,
      ));
    } catch (e) {

      emit(PagePostsErrorState(e.toString()));
    }
  }

  Future<void> _onRefreshPagePosts(RefreshPagePostsEvent event, Emitter<PagePostsState> emit) async {
    try {
      _currentPage = 0; // إعادة تعيين الصفحة
      _currentPageId = event.pageId; // حفظ معرف الصفحة الحالية
      
      final response = await _repository.fetchPagePosts(
        pageId: event.pageId,
        limit: _pageSize,
        offset: _currentPage,
      );
      
      emit(PagePostsLoadedState(
        posts: response.posts,
        pageId: event.pageId,
        hasMore: response.hasMore,
      ));
    } catch (e) {
      emit(PagePostsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadMorePagePosts(LoadMorePagePostsEvent event, Emitter<PagePostsState> emit) async {
    if (state is! PagePostsLoadedState) return;
    
    final currentState = state as PagePostsLoadedState;
    if (!currentState.hasMore || currentState.isLoadingMore) {

      return;
    }

    if (_currentPageId == null) {

      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    
    try {
      _currentPage++; // زيادة رقم الصفحة
      
      final response = await _repository.fetchPagePosts(
        pageId: _currentPageId!,
        limit: _pageSize,
        offset: _currentPage,
      );

      // تجنب المنشورات المكررة
      final currentPostIds = currentState.posts.map((p) => p.id).toSet();
      final uniqueNewPosts = response.posts.where((post) => !currentPostIds.contains(post.id)).toList();

      final newPosts = List<Post>.from(currentState.posts)..addAll(uniqueNewPosts);
      
      emit(PagePostsLoadedState(
        posts: newPosts,
        pageId: currentState.pageId,
        hasMore: response.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {

      _currentPage--; // التراجع عن زيادة الصفحة في حالة الخطأ
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onAddPostToPage(AddPostToPageEvent event, Emitter<PagePostsState> emit) {
    if (state is PagePostsLoadedState) {
      final currentState = state as PagePostsLoadedState;
      final newPosts = List<Post>.from([event.post])..addAll(currentState.posts);
      emit(currentState.copyWith(posts: newPosts));
    }
  }

  void _onUpdatePostInPage(UpdatePostInPageEvent event, Emitter<PagePostsState> emit) {
    if (state is PagePostsLoadedState) {
      final currentState = state as PagePostsLoadedState;
      final newPosts = currentState.posts.map((post) {
        return post.id == event.post.id ? event.post : post;
      }).toList();
      emit(currentState.copyWith(posts: newPosts));
    }
  }

  void _onDeletePostFromPage(DeletePostFromPageEvent event, Emitter<PagePostsState> emit) {
    if (state is PagePostsLoadedState) {
      final currentState = state as PagePostsLoadedState;
      final newPosts = currentState.posts.where((post) => post.id != event.postId).toList();
      emit(currentState.copyWith(posts: newPosts));
    }
  }

  Future<void> _onReactToPostInPage(ReactToPostInPageEvent event, Emitter<PagePostsState> emit) async {
    if (state is PagePostsLoadedState) {
      final currentState = state as PagePostsLoadedState;
      
      // Optimistic update
      final newPosts = currentState.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWithReaction(event.reaction);
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: newPosts));
      
      try {
        await _repository.reactToPost(event.postId, event.reaction);
      } catch (e) {
        // Revert on error
        emit(currentState);
      }
    }
  }
}