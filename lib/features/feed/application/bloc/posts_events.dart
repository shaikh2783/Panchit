import 'package:snginepro/core/bloc/base_bloc.dart';
import 'package:snginepro/features/feed/data/models/post.dart';

// Events
abstract class PostsEvent extends BaseEvent {}

class LoadPostsEvent extends PostsEvent {}
class RefreshPostsEvent extends PostsEvent {}
class LoadMorePostsEvent extends PostsEvent {}
class AddPostEvent extends PostsEvent {
  final Post post;
  AddPostEvent(this.post);
  
  @override
  List<Object?> get props => [post];
}

class UpdatePostEvent extends PostsEvent {
  final Post post;
  UpdatePostEvent(this.post);
  
  @override
  List<Object?> get props => [post];
}

class DeletePostEvent extends PostsEvent {
  final int postId;
  DeletePostEvent(this.postId);
  
  @override
  List<Object?> get props => [postId];
}

class ReactToPostEvent extends PostsEvent {
  final int postId;
  final String reaction;
  ReactToPostEvent(this.postId, this.reaction);
  
  @override
  List<Object?> get props => [postId, reaction];
}

// 💰 PROMOTED POSTS EVENTS
class LoadPromotedPostEvent extends PostsEvent {}

class PromotedPostLoadedEvent extends PostsEvent {
  final Post? post;
  PromotedPostLoadedEvent(this.post);
  
  @override
  List<Object?> get props => [post];
}

// States
abstract class PostsState extends BaseState {}

class PostsInitialState extends PostsState {}

class PostsLoadingState extends PostsState {}

class PostsLoadedState extends PostsState {
  final List<Post> posts;
  final bool hasMore;
  final bool isLoadingMore;
  
  PostsLoadedState({
    required this.posts,
    this.hasMore = true,
    this.isLoadingMore = false,
  });
  
  @override
  List<Object?> get props => [posts, hasMore, isLoadingMore];
  
  PostsLoadedState copyWith({
    List<Post>? posts,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PostsLoadedState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PostsErrorState extends PostsState {
  final String message;
  PostsErrorState(this.message);
  
  @override
  List<Object?> get props => [message];
}