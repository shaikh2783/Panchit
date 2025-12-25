import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import '../../data/repositories/groups_repository.dart';

// Events
abstract class GroupPostsEvent {}

class LoadGroupPostsEvent extends GroupPostsEvent {
  final String groupId;
  LoadGroupPostsEvent(this.groupId);
}

class LoadMoreGroupPostsEvent extends GroupPostsEvent {
  LoadMoreGroupPostsEvent();
}

class RefreshGroupPostsEvent extends GroupPostsEvent {
  final String groupId;
  RefreshGroupPostsEvent(this.groupId);
}

class AddPostToGroupEvent extends GroupPostsEvent {
  final Post post;
  AddPostToGroupEvent(this.post);
}

class UpdatePostInGroupEvent extends GroupPostsEvent {
  final Post post;
  UpdatePostInGroupEvent(this.post);
}

class DeletePostFromGroupEvent extends GroupPostsEvent {
  final int postId;
  DeletePostFromGroupEvent(this.postId);
}

class ReactToPostInGroupEvent extends GroupPostsEvent {
  final int postId;
  final String reaction;
  ReactToPostInGroupEvent(this.postId, this.reaction);
}

// States
abstract class GroupPostsState {}

class GroupPostsInitialState extends GroupPostsState {}

class GroupPostsLoadingState extends GroupPostsState {}

class GroupPostsLoadedState extends GroupPostsState {
  final List<Post> posts;
  final String groupId;
  final bool hasMore;
  final bool isLoadingMore;

  GroupPostsLoadedState({
    required this.posts,
    required this.groupId,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  GroupPostsLoadedState copyWith({
    List<Post>? posts,
    String? groupId,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GroupPostsLoadedState(
      posts: posts ?? this.posts,
      groupId: groupId ?? this.groupId,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class GroupPostsErrorState extends GroupPostsState {
  final String message;
  GroupPostsErrorState(this.message);
}

// Bloc
class GroupPostsBloc extends Bloc<GroupPostsEvent, GroupPostsState> {
  final GroupsRepository _repository;
  final int _pageSize = 20;
  int _currentPage = 0;
  String? _currentGroupId;

  GroupPostsBloc(this._repository) : super(GroupPostsInitialState()) {
    on<LoadGroupPostsEvent>(_onLoadGroupPosts);
    on<LoadMoreGroupPostsEvent>(_onLoadMoreGroupPosts);
    on<RefreshGroupPostsEvent>(_onRefreshGroupPosts);
    on<AddPostToGroupEvent>(_onAddPostToGroup);
    on<UpdatePostInGroupEvent>(_onUpdatePostInGroup);
    on<DeletePostFromGroupEvent>(_onDeletePostFromGroup);
    on<ReactToPostInGroupEvent>(_onReactToPostInGroup);
  }

  Future<void> _onLoadGroupPosts(
    LoadGroupPostsEvent event,
    Emitter<GroupPostsState> emit,
  ) async {
    emit(GroupPostsLoadingState());

    try {
      _currentPage = 0;
      _currentGroupId = event.groupId;

      final response = await _repository.fetchGroupPosts(
        groupId: event.groupId,
        limit: _pageSize,
        offset: _currentPage,
      );


      emit(
        GroupPostsLoadedState(
          posts: response.posts,
          groupId: event.groupId,
          hasMore: response.hasMore,
        ),
      );
    } catch (e) {
      emit(GroupPostsErrorState(e.toString()));
    }
  }

  Future<void> _onRefreshGroupPosts(
    RefreshGroupPostsEvent event,
    Emitter<GroupPostsState> emit,
  ) async {
    try {
      _currentPage = 0;
      _currentGroupId = event.groupId;

      final response = await _repository.fetchGroupPosts(
        groupId: event.groupId,
        limit: _pageSize,
        offset: _currentPage,
      );

      emit(
        GroupPostsLoadedState(
          posts: response.posts,
          groupId: event.groupId,
          hasMore: response.hasMore,
        ),
      );
    } catch (e) {
      emit(GroupPostsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadMoreGroupPosts(
    LoadMoreGroupPostsEvent event,
    Emitter<GroupPostsState> emit,
  ) async {
    if (state is! GroupPostsLoadedState) return;

    final currentState = state as GroupPostsLoadedState;

    // تجنب التحميل المتعدد
    if (currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // تحديث الحالة لإظهار مؤشر التحميل
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      _currentPage += _pageSize;

      final response = await _repository.fetchGroupPosts(
        groupId: _currentGroupId!,
        limit: _pageSize,
        offset: _currentPage,
      );


      final updatedPosts = [...currentState.posts, ...response.posts];

      emit(
        GroupPostsLoadedState(
          posts: updatedPosts,
          groupId: currentState.groupId,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      // إرجاع الحالة السابقة في حالة الخطأ
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  void _onAddPostToGroup(
    AddPostToGroupEvent event,
    Emitter<GroupPostsState> emit,
  ) {
    if (state is GroupPostsLoadedState) {
      final currentState = state as GroupPostsLoadedState;
      final updatedPosts = [event.post, ...currentState.posts];
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }

  void _onUpdatePostInGroup(
    UpdatePostInGroupEvent event,
    Emitter<GroupPostsState> emit,
  ) {
    if (state is GroupPostsLoadedState) {
      final currentState = state as GroupPostsLoadedState;
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.post.id) {
          return event.post;
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }

  void _onDeletePostFromGroup(
    DeletePostFromGroupEvent event,
    Emitter<GroupPostsState> emit,
  ) {
    if (state is GroupPostsLoadedState) {
      final currentState = state as GroupPostsLoadedState;
      final updatedPosts = currentState.posts
          .where((post) => post.id != event.postId)
          .toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }

  void _onReactToPostInGroup(
    ReactToPostInGroupEvent event,
    Emitter<GroupPostsState> emit,
  ) {
    if (state is GroupPostsLoadedState) {
      final currentState = state as GroupPostsLoadedState;
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.postId) {
          // تحديث التفاعل في المنشور
          // Note: Post model قد يحتاج إلى copyWith method لتحديث الـ reaction
          // أو يمكن استخدام نفس المنشور إذا كان immutable
          return post;
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }
}
