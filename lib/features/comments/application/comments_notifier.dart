import 'package:flutter/foundation.dart';
import '../data/models/comment.dart';
import '../domain/comments_repository.dart';

class CommentsNotifier extends ChangeNotifier {
  final CommentsRepository _repository;

  CommentsNotifier(this._repository);

  // State
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentOffset = 0;
  bool _hasMore = true;
  final int _limit = 20;

  // Getters
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get commentsCount => _comments.length;

  // Fetch initial comments
  Future<void> fetchComments(int postId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentOffset = 0;
    notifyListeners();

    try {
      final response = await _repository.getPostComments(
        postId,
        offset: _currentOffset,
        limit: _limit,
      );

      _comments = response.comments;
      _hasMore = response.hasMore;
      _currentOffset = response.comments.length;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _comments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more comments (pagination)
  Future<void> loadMoreComments(int postId) async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _repository.getPostComments(
        postId,
        offset: _currentOffset,
        limit: _limit,
      );

      _comments.addAll(response.comments);
      _hasMore = response.hasMore;
      _currentOffset = _comments.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Create a new comment
  Future<CommentModel?> createComment({
    required int postId,
    required String text,
    String? image,
    String? voiceNote,
  }) async {
    try {
      final newComment = await _repository.createComment(
        postId: postId,
        text: text,
        image: image,
        voiceNote: voiceNote,
      );

      // Add to the beginning of the list
      _comments.insert(0, newComment);
      notifyListeners();

      return newComment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // React to a comment (optimistic update)
  Future<void> reactToComment({
    required String commentId,
    required String reaction,
  }) async {
    // Find comment index
    final index = _comments.indexWhere((c) => c.commentId == commentId);
    if (index == -1) return;

    // Store old state for rollback
    final oldComment = _comments[index];

    // Optimistic update
    final wasReacted = oldComment.iReact;
    final oldReaction = oldComment.iReaction;

    Map<String, int> newReactions = Map.from(oldComment.reactions);
    bool newIReact = false;
    String? newIReaction;
    int newTotal = oldComment.reactionsTotalCount;

    if (reaction == 'remove') {
      // Remove reaction
      if (wasReacted && oldReaction != null) {
        newReactions[oldReaction] = (newReactions[oldReaction] ?? 1) - 1;
        newTotal -= 1;
      }
    } else {
      // Add or change reaction
      if (wasReacted && oldReaction != null && oldReaction != reaction) {
        // Change reaction
        newReactions[oldReaction] = (newReactions[oldReaction] ?? 1) - 1;
        newReactions[reaction] = (newReactions[reaction] ?? 0) + 1;
      } else if (!wasReacted) {
        // Add new reaction
        newReactions[reaction] = (newReactions[reaction] ?? 0) + 1;
        newTotal += 1;
      }
      newIReact = true;
      newIReaction = reaction;
    }

    _comments[index] = oldComment.copyWith(
      reactions: newReactions,
      reactionsTotalCount: newTotal,
      iReact: newIReact,
      iReaction: newIReaction,
    );
    notifyListeners();

    // Make API call
    try {
      await _repository.reactToComment(
        commentId: int.parse(commentId),
        reaction: reaction,
      );
    } catch (e) {
      // Rollback on error
      _comments[index] = oldComment;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Edit a comment
  Future<bool> editComment({
    required String commentId,
    required String newText,
  }) async {
    try {
      final result = await _repository.editComment(
        commentId: int.parse(commentId),
        newText: newText,
      );

      // Update comment in list with the returned comment data
      final index = _comments.indexWhere((c) => c.commentId == commentId);
      if (index != -1) {
        // Parse the updated comment from API response
        _comments[index] = CommentModel.fromJson(result);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(int.parse(commentId));

      // Remove from list
      _comments.removeWhere((c) => c.commentId == commentId);
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Increment replies count when a reply is added
  void incrementRepliesCount(String commentId) {
    final index = _comments.indexWhere((c) => c.commentId == commentId);
    if (index != -1) {
      _comments[index] = _comments[index].copyWith(
        repliesCount: _comments[index].repliesCount + 1,
      );
      notifyListeners();
    }
  }

  // Reset state
  void reset() {
    _comments = [];
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    _currentOffset = 0;
    _hasMore = true;
    notifyListeners();
  }
}
