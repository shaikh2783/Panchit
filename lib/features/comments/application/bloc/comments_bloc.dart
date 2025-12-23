import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/comments/data/models/comment.dart';
import 'package:snginepro/features/comments/domain/comments_repository.dart';

// Events
abstract class CommentsEvent extends BaseEvent {}

class LoadCommentsEvent extends CommentsEvent {
  final int postId;

  LoadCommentsEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class LoadMoreCommentsEvent extends CommentsEvent {}

class RefreshCommentsEvent extends CommentsEvent {
  final int postId;

  RefreshCommentsEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class AddCommentEvent extends CommentsEvent {
  final int postId;
  final String content;
  final int? parentCommentId;

  AddCommentEvent({
    required this.postId,
    required this.content,
    this.parentCommentId,
  });

  @override
  List<Object?> get props => [postId, content, parentCommentId];
}

class UpdateCommentEvent extends CommentsEvent {
  final int commentId;
  final String content;

  UpdateCommentEvent({required this.commentId, required this.content});

  @override
  List<Object?> get props => [commentId, content];
}

class DeleteCommentEvent extends CommentsEvent {
  final int commentId;

  DeleteCommentEvent(this.commentId);

  @override
  List<Object?> get props => [commentId];
}

class LikeCommentEvent extends CommentsEvent {
  final int commentId;

  LikeCommentEvent(this.commentId);

  @override
  List<Object?> get props => [commentId];
}

class LoadRepliesEvent extends CommentsEvent {
  final int commentId;

  LoadRepliesEvent(this.commentId);

  @override
  List<Object?> get props => [commentId];
}

// States
abstract class CommentsState extends BaseState {
  const CommentsState({
    super.isLoading,
    super.errorMessage,
    this.comments = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentOffset = 0,
    this.postId,
  });

  final List<CommentModel> comments;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentOffset;
  final int? postId;

  @override
  List<Object?> get props => [
        ...super.props,
        comments,
        hasMore,
        isLoadingMore,
        currentOffset,
        postId,
      ];
}

class CommentsInitial extends CommentsState {
  const CommentsInitial();
}

class CommentsLoading extends CommentsState {
  const CommentsLoading({
    super.comments,
    super.hasMore,
    super.currentOffset,
    super.postId,
  }) : super(isLoading: true);
}

class CommentsLoadingMore extends CommentsState {
  const CommentsLoadingMore({
    required super.comments,
    required super.hasMore,
    required super.currentOffset,
    required super.postId,
  }) : super(isLoadingMore: true);
}

class CommentsLoaded extends CommentsState {
  const CommentsLoaded({
    required super.comments,
    required super.hasMore,
    required super.currentOffset,
    required super.postId,
  });
}

class CommentsError extends CommentsState {
  const CommentsError(
    String message, {
    super.comments,
    super.hasMore,
    super.currentOffset,
    super.postId,
  }) : super(errorMessage: message);
}

class CommentAdded extends CommentsState {
  final CommentModel newComment;

  const CommentAdded({
    required this.newComment,
    required super.comments,
    required super.hasMore,
    required super.currentOffset,
    required super.postId,
  });

  @override
  List<Object?> get props => [...super.props, newComment];
}

class CommentUpdated extends CommentsState {
  final CommentModel updatedComment;

  const CommentUpdated({
    required this.updatedComment,
    required super.comments,
    required super.hasMore,
    required super.currentOffset,
    required super.postId,
  });

  @override
  List<Object?> get props => [...super.props, updatedComment];
}

class CommentDeleted extends CommentsState {
  final int deletedCommentId;

  const CommentDeleted({
    required this.deletedCommentId,
    required super.comments,
    required super.hasMore,
    required super.currentOffset,
    required super.postId,
  });

  @override
  List<Object?> get props => [...super.props, deletedCommentId];
}

class CommentLiked extends CommentsState {
  final CommentModel likedComment;

  const CommentLiked({
    required this.likedComment,
    required super.comments,
    required super.hasMore,
    required super.currentOffset,
    required super.postId,
  });

  @override
  List<Object?> get props => [...super.props, likedComment];
}

// Bloc
class CommentsBloc extends BaseBloc<CommentsEvent, CommentsState> {
  CommentsBloc(this._repository) : super(const CommentsInitial()) {
    on<LoadCommentsEvent>(_onLoadComments);
    on<LoadMoreCommentsEvent>(_onLoadMoreComments);
    on<RefreshCommentsEvent>(_onRefreshComments);
    on<AddCommentEvent>(_onAddComment);
    on<UpdateCommentEvent>(_onUpdateComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<LikeCommentEvent>(_onLikeComment);
    on<LoadRepliesEvent>(_onLoadReplies);
  }

  final CommentsRepository _repository;
  static const int _limit = 20;

  Future<void> _onLoadComments(
    LoadCommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    emit(CommentsLoading(
      comments: state.comments,
      hasMore: state.hasMore,
      currentOffset: state.currentOffset,
      postId: event.postId,
    ));

    try {
      final response = await _repository.getPostComments(
        event.postId,
        offset: 0,
        limit: _limit,
      );

      emit(CommentsLoaded(
        comments: response.comments,
        hasMore: response.hasMore,
        currentOffset: response.comments.length,
        postId: event.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: event.postId,
      ));
    } catch (e) {
      emit(CommentsError(
        e.toString(),
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: event.postId,
      ));
    }
  }

  Future<void> _onLoadMoreComments(
    LoadMoreCommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore || state.postId == null) return;

    emit(CommentsLoadingMore(
      comments: state.comments,
      hasMore: state.hasMore,
      currentOffset: state.currentOffset,
      postId: state.postId!,
    ));

    try {
      final response = await _repository.getPostComments(
        state.postId!,
        offset: state.currentOffset,
        limit: _limit,
      );

      emit(CommentsLoaded(
        comments: [...state.comments, ...response.comments],
        hasMore: response.hasMore,
        currentOffset: state.currentOffset + response.comments.length,
        postId: state.postId!,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    } catch (e) {
      emit(CommentsError(
        e.toString(),
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    }
  }

  Future<void> _onRefreshComments(
    RefreshCommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      final response = await _repository.getPostComments(
        event.postId,
        offset: 0,
        limit: _limit,
      );

      emit(CommentsLoaded(
        comments: response.comments,
        hasMore: response.hasMore,
        currentOffset: response.comments.length,
        postId: event.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: event.postId,
      ));
    }
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      final newComment = await _repository.createComment(
        postId: event.postId,
        text: event.content,
      );

      // Add the new comment to the beginning of the list
      final updatedComments = [newComment, ...state.comments];

      emit(CommentAdded(
        newComment: newComment,
        comments: updatedComments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset + 1,
        postId: state.postId ?? event.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    }
  }

  Future<void> _onUpdateComment(
    UpdateCommentEvent event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      await _repository.editComment(
        commentId: event.commentId,
        newText: event.content,
      );

      // Update the comment in the list
      final updatedComments = state.comments.map((comment) {
        return comment.commentId == event.commentId.toString()
            ? comment.copyWith(text: event.content, textPlain: event.content)
            : comment;
      }).toList();

      // Find the updated comment for the state
      final updatedComment = updatedComments.firstWhere(
        (comment) => comment.commentId == event.commentId.toString(),
      );

      emit(CommentUpdated(
        updatedComment: updatedComment,
        comments: updatedComments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    }
  }

  Future<void> _onDeleteComment(
    DeleteCommentEvent event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      await _repository.deleteComment(event.commentId);

      // Remove the comment from the list
      final updatedComments = state.comments
          .where((comment) => comment.commentId != event.commentId.toString())
          .toList();

      emit(CommentDeleted(
        deletedCommentId: event.commentId,
        comments: updatedComments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset - 1,
        postId: state.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    }
  }

  Future<void> _onLikeComment(
    LikeCommentEvent event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      // Use 'like' as the default reaction
      await _repository.reactToComment(
        commentId: event.commentId,
        reaction: 'like',
      );

      // Update the comment's reaction status in the list
      final updatedComments = state.comments.map((comment) {
        if (comment.commentId == event.commentId.toString()) {
          final currentReactions = Map<String, int>.from(comment.reactions);
          final wasLiked = comment.iReact;
          
          if (wasLiked) {
            // Remove reaction
            currentReactions['like'] = (currentReactions['like'] ?? 0) - 1;
          } else {
            // Add reaction
            currentReactions['like'] = (currentReactions['like'] ?? 0) + 1;
          }

          return comment.copyWith(
            iReact: !wasLiked,
            iReaction: wasLiked ? null : 'like',
            reactions: currentReactions,
            reactionsTotalCount: wasLiked 
                ? comment.reactionsTotalCount - 1 
                : comment.reactionsTotalCount + 1,
          );
        }
        return comment;
      }).toList();

      // Find the updated comment for the state
      final likedComment = updatedComments.firstWhere(
        (comment) => comment.commentId == event.commentId.toString(),
      );

      emit(CommentLiked(
        likedComment: likedComment,
        comments: updatedComments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    }
  }

  Future<void> _onLoadReplies(
    LoadRepliesEvent event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      final repliesResponse = await _repository.getCommentReplies(event.commentId);

      // For now, we'll just trigger a reload of comments
      // In a more complete implementation, you'd merge replies into the comment structure
      emit(CommentsLoaded(
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    } on ApiException catch (e) {
      emit(CommentsError(
        e.message,
        comments: state.comments,
        hasMore: state.hasMore,
        currentOffset: state.currentOffset,
        postId: state.postId,
      ));
    }
  }
}