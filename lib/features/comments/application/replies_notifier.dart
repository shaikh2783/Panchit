import 'package:flutter/foundation.dart';
import '../data/models/comment.dart';
import '../domain/comments_repository.dart';
class RepliesNotifier extends ChangeNotifier {
  final CommentsRepository _repository;
  RepliesNotifier(this._repository);
  // State for each comment's replies
  final Map<String, List<CommentModel>> _repliesMap = {};
  final Map<String, bool> _isLoadingMap = {};
  final Map<String, bool> _isLoadingMoreMap = {};
  final Map<String, String?> _errorMap = {};
  final Map<String, int> _offsetMap = {};
  final Map<String, bool> _hasMoreMap = {};
  final int _limit = 10;
  // Getters
  List<CommentModel> getReplies(String commentId) => _repliesMap[commentId] ?? [];
  bool isLoading(String commentId) => _isLoadingMap[commentId] ?? false;
  bool isLoadingMore(String commentId) => _isLoadingMoreMap[commentId] ?? false;
  String? getError(String commentId) => _errorMap[commentId];
  bool hasMore(String commentId) => _hasMoreMap[commentId] ?? true;
  int getRepliesCount(String commentId) => _repliesMap[commentId]?.length ?? 0;
  // Fetch initial replies
  Future<void> fetchReplies(int commentId) async {
    final commentIdStr = commentId.toString();
    if (_isLoadingMap[commentIdStr] == true) return;
    _isLoadingMap[commentIdStr] = true;
    _errorMap[commentIdStr] = null;
    _offsetMap[commentIdStr] = 0;
    notifyListeners();
    try {
      final response = await _repository.getCommentReplies(
        commentId,
        offset: 0,
        limit: _limit,
      );
      _repliesMap[commentIdStr] = response.replies;
      _hasMoreMap[commentIdStr] = response.hasMore;
      _offsetMap[commentIdStr] = response.replies.length;
      _errorMap[commentIdStr] = null;
    } catch (e) {
      _errorMap[commentIdStr] = e.toString();
      _repliesMap[commentIdStr] = [];
    } finally {
      _isLoadingMap[commentIdStr] = false;
      notifyListeners();
    }
  }
  // Load more replies
  Future<void> loadMoreReplies(int commentId) async {
    final commentIdStr = commentId.toString();
    if (_isLoadingMoreMap[commentIdStr] == true || 
        _hasMoreMap[commentIdStr] == false ||
        _isLoadingMap[commentIdStr] == true) {
      return;
    }
    _isLoadingMoreMap[commentIdStr] = true;
    notifyListeners();
    try {
      final response = await _repository.getCommentReplies(
        commentId,
        offset: _offsetMap[commentIdStr] ?? 0,
        limit: _limit,
      );
      final currentReplies = _repliesMap[commentIdStr] ?? [];
      _repliesMap[commentIdStr] = [...currentReplies, ...response.replies];
      _hasMoreMap[commentIdStr] = response.hasMore;
      _offsetMap[commentIdStr] = _repliesMap[commentIdStr]!.length;
    } catch (e) {
      _errorMap[commentIdStr] = e.toString();
    } finally {
      _isLoadingMoreMap[commentIdStr] = false;
      notifyListeners();
    }
  }
  // Create a reply
  Future<CommentModel?> createReply({
    required int commentId,
    required String text,
    String? image,
    String? voiceNote,
  }) async {
    try {
      final newReply = await _repository.createReply(
        commentId: commentId,
        text: text,
        image: image,
        voiceNote: voiceNote,
      );
      // Add to the beginning of the list
      final commentIdStr = commentId.toString();
      final currentReplies = _repliesMap[commentIdStr] ?? [];
      _repliesMap[commentIdStr] = [newReply, ...currentReplies];
      notifyListeners();
      return newReply;
    } catch (e) {
      final commentIdStr = commentId.toString();
      _errorMap[commentIdStr] = e.toString();
      notifyListeners();
      return null;
    }
  }
  // React to a reply (optimistic update)
  Future<void> reactToReply({
    required String parentCommentId,
    required String replyId,
    required String reaction,
  }) async {
    final replies = _repliesMap[parentCommentId];
    if (replies == null) return;
    // Find reply index
    final index = replies.indexWhere((r) => r.commentId == replyId);
    if (index == -1) return;
    // Store old state for rollback
    final oldReply = replies[index];
    // Optimistic update (same logic as comment reaction)
    final wasReacted = oldReply.iReact;
    final oldReaction = oldReply.iReaction;
    Map<String, int> newReactions = Map.from(oldReply.reactions);
    bool newIReact = false;
    String? newIReaction;
    int newTotal = oldReply.reactionsTotalCount;
    if (reaction == 'remove') {
      if (wasReacted && oldReaction != null) {
        newReactions[oldReaction] = (newReactions[oldReaction] ?? 1) - 1;
        newTotal -= 1;
      }
    } else {
      if (wasReacted && oldReaction != null && oldReaction != reaction) {
        newReactions[oldReaction] = (newReactions[oldReaction] ?? 1) - 1;
        newReactions[reaction] = (newReactions[reaction] ?? 0) + 1;
      } else if (!wasReacted) {
        newReactions[reaction] = (newReactions[reaction] ?? 0) + 1;
        newTotal += 1;
      }
      newIReact = true;
      newIReaction = reaction;
    }
    replies[index] = oldReply.copyWith(
      reactions: newReactions,
      reactionsTotalCount: newTotal,
      iReact: newIReact,
      iReaction: newIReaction,
    );
    notifyListeners();
    // Make API call
    try {
      await _repository.reactToComment(
        commentId: int.parse(replyId),
        reaction: reaction,
      );
    } catch (e) {
      // Rollback on error
      replies[index] = oldReply;
      _errorMap[parentCommentId] = e.toString();
      notifyListeners();
    }
  }
  // Edit a reply
  Future<bool> editReply({
    required String parentCommentId,
    required String replyId,
    required String newText,
  }) async {
    try {
      final result = await _repository.editComment(
        commentId: int.parse(replyId),
        newText: newText,
      );
      // Update reply in list with the returned comment data
      final replies = _repliesMap[parentCommentId];
      if (replies != null) {
        final index = replies.indexWhere((r) => r.commentId == replyId);
        if (index != -1) {
          // Parse the updated comment from API response
          replies[index] = CommentModel.fromJson(result);
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _errorMap[parentCommentId] = e.toString();
      notifyListeners();
      return false;
    }
  }
  // Delete a reply
  Future<bool> deleteReply({
    required String parentCommentId,
    required String replyId,
  }) async {
    try {
      await _repository.deleteComment(int.parse(replyId));
      // Remove from list
      final replies = _repliesMap[parentCommentId];
      if (replies != null) {
        replies.removeWhere((r) => r.commentId == replyId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMap[parentCommentId] = e.toString();
      notifyListeners();
      return false;
    }
  }
  // Clear replies for a comment
  void clearReplies(String commentId) {
    _repliesMap.remove(commentId);
    _isLoadingMap.remove(commentId);
    _isLoadingMoreMap.remove(commentId);
    _errorMap.remove(commentId);
    _offsetMap.remove(commentId);
    _hasMoreMap.remove(commentId);
    notifyListeners();
  }
  // Reset all state
  void reset() {
    _repliesMap.clear();
    _isLoadingMap.clear();
    _isLoadingMoreMap.clear();
    _errorMap.clear();
    _offsetMap.clear();
    _hasMoreMap.clear();
    notifyListeners();
  }
}
