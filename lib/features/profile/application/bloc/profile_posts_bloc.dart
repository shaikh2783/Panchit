import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/feed/domain/posts_repository.dart';
// Events
abstract class ProfilePostsEvent {}
class LoadUserPostsEvent extends ProfilePostsEvent {
  final String userId;
  LoadUserPostsEvent(this.userId);
}
class LoadMoreUserPostsEvent extends ProfilePostsEvent {
  LoadMoreUserPostsEvent();
}
class RefreshUserPostsEvent extends ProfilePostsEvent {
  final String userId;
  RefreshUserPostsEvent(this.userId);
}
class AddPostToProfileEvent extends ProfilePostsEvent {
  final Post post;
  AddPostToProfileEvent(this.post);
}
class UpdatePostInProfileEvent extends ProfilePostsEvent {
  final Post post;
  UpdatePostInProfileEvent(this.post);
}
class DeletePostFromProfileEvent extends ProfilePostsEvent {
  final int postId;
  DeletePostFromProfileEvent(this.postId);
}
class ReactToPostInProfileEvent extends ProfilePostsEvent {
  final int postId;
  final String reaction;
  ReactToPostInProfileEvent(this.postId, this.reaction);
}
// States
abstract class ProfilePostsState {}
class ProfilePostsInitialState extends ProfilePostsState {}
class ProfilePostsLoadingState extends ProfilePostsState {}
class ProfilePostsLoadedState extends ProfilePostsState {
  final List<Post> posts;
  final String userId;
  final bool hasMore;
  final bool isLoadingMore;
  ProfilePostsLoadedState({
    required this.posts,
    required this.userId,
    this.hasMore = false,
    this.isLoadingMore = false,
  });
  ProfilePostsLoadedState copyWith({
    List<Post>? posts,
    String? userId,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ProfilePostsLoadedState(
      posts: posts ?? this.posts,
      userId: userId ?? this.userId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
class ProfilePostsErrorState extends ProfilePostsState {
  final String message;
  ProfilePostsErrorState(this.message);
}
// Bloc
class ProfilePostsBloc extends Bloc<ProfilePostsEvent, ProfilePostsState> {
  final PostsRepository _repository;
  final int _pageSize = 20;
  int _currentPage = 0; // متتبع الصفحة الحالية
  String? _currentUserId; // متتبع المستخدم الحالي
  ProfilePostsBloc(this._repository) : super(ProfilePostsInitialState()) {
    on<LoadUserPostsEvent>(_onLoadUserPosts);
    on<LoadMoreUserPostsEvent>(_onLoadMoreUserPosts);
    on<RefreshUserPostsEvent>(_onRefreshUserPosts);
    on<AddPostToProfileEvent>(_onAddPostToProfile);
    on<UpdatePostInProfileEvent>(_onUpdatePostInProfile);
    on<DeletePostFromProfileEvent>(_onDeletePostFromProfile);
    on<ReactToPostInProfileEvent>(_onReactToPostInProfile);
  }
  Future<void> _onLoadUserPosts(LoadUserPostsEvent event, Emitter<ProfilePostsState> emit) async {
    emit(ProfilePostsLoadingState());
    try {
      _currentPage = 0; // إعادة تعيين الصفحة
      _currentUserId = event.userId; // حفظ المستخدم الحالي
      final response = await _repository.fetchUserPosts(
        userId: int.parse(event.userId),
        limit: _pageSize,
        offset: _currentPage,
      );
      emit(ProfilePostsLoadedState(
        posts: response.posts,
        userId: event.userId,
        hasMore: response.hasMore,
      ));
    } catch (e) {
      emit(ProfilePostsErrorState(e.toString()));
    }
  }
  Future<void> _onRefreshUserPosts(RefreshUserPostsEvent event, Emitter<ProfilePostsState> emit) async {
    try {
      _currentPage = 0; // إعادة تعيين الصفحة
      _currentUserId = event.userId; // حفظ المستخدم الحالي
      final response = await _repository.fetchUserPosts(
        userId: int.parse(event.userId),
        limit: _pageSize,
        offset: _currentPage,
      );
      emit(ProfilePostsLoadedState(
        posts: response.posts,
        userId: event.userId,
        hasMore: response.hasMore,
      ));
    } catch (e) {
      emit(ProfilePostsErrorState(e.toString()));
    }
  }
  Future<void> _onLoadMoreUserPosts(LoadMoreUserPostsEvent event, Emitter<ProfilePostsState> emit) async {
    if (state is! ProfilePostsLoadedState) return;
    final currentState = state as ProfilePostsLoadedState;
    if (!currentState.hasMore || currentState.isLoadingMore) {
      return;
    }
    if (_currentUserId == null) {
      return;
    }
    emit(currentState.copyWith(isLoadingMore: true));
    try {
      _currentPage++; // زيادة رقم الصفحة
      final response = await _repository.fetchUserPosts(
        userId: int.parse(_currentUserId!),
        limit: _pageSize,
        offset: _currentPage,
      );
      // تجنب المنشورات المكررة
      final currentPostIds = currentState.posts.map((p) => p.id).toSet();
      final uniqueNewPosts = response.posts.where((post) => !currentPostIds.contains(post.id)).toList();
      final newPosts = List<Post>.from(currentState.posts)..addAll(uniqueNewPosts);
      emit(ProfilePostsLoadedState(
        posts: newPosts,
        userId: currentState.userId,
        hasMore: response.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      _currentPage--; // التراجع عن زيادة الصفحة في حالة الخطأ
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
  void _onAddPostToProfile(AddPostToProfileEvent event, Emitter<ProfilePostsState> emit) {
    if (state is ProfilePostsLoadedState) {
      final currentState = state as ProfilePostsLoadedState;
      final newPosts = List<Post>.from([event.post])..addAll(currentState.posts);
      emit(currentState.copyWith(posts: newPosts));
    }
  }
  void _onUpdatePostInProfile(UpdatePostInProfileEvent event, Emitter<ProfilePostsState> emit) {
    if (state is ProfilePostsLoadedState) {
      final currentState = state as ProfilePostsLoadedState;
      final newPosts = currentState.posts.map((post) {
        return post.id == event.post.id ? event.post : post;
      }).toList();
      emit(currentState.copyWith(posts: newPosts));
    }
  }
  void _onDeletePostFromProfile(DeletePostFromProfileEvent event, Emitter<ProfilePostsState> emit) {
    if (state is ProfilePostsLoadedState) {
      final currentState = state as ProfilePostsLoadedState;
      final newPosts = currentState.posts.where((post) => post.id != event.postId).toList();
      emit(currentState.copyWith(posts: newPosts));
    }
  }
  Future<void> _onReactToPostInProfile(ReactToPostInProfileEvent event, Emitter<ProfilePostsState> emit) async {
    if (state is ProfilePostsLoadedState) {
      final currentState = state as ProfilePostsLoadedState;
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