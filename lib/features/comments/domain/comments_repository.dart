import '../data/datasources/comments_api_service.dart';
import '../data/models/comment.dart';
import '../data/models/comments_response.dart';

class CommentsRepository {
  final CommentsApiService _apiService;

  CommentsRepository(this._apiService);

  Future<CommentsResponse> getPostComments(
    int postId, {
    int offset = 0,
    int limit = 20,
  }) async {
    return await _apiService.getPostComments(
      postId,
      offset: offset,
      limit: limit,
    );
  }

  Future<CommentModel> createComment({
    required int postId,
    required String text,
    String? image,
    String? voiceNote,
  }) async {
    return await _apiService.createComment(
      postId: postId,
      text: text,
      image: image,
      voiceNote: voiceNote,
    );
  }

  Future<RepliesResponse> getCommentReplies(
    int commentId, {
    int offset = 0,
    int limit = 10,
  }) async {
    return await _apiService.getCommentReplies(
      commentId,
      offset: offset,
      limit: limit,
    );
  }

  Future<CommentModel> createReply({
    required int commentId,
    required String text,
    String? image,
    String? voiceNote,
  }) async {
    return await _apiService.createReply(
      commentId: commentId,
      text: text,
      image: image,
      voiceNote: voiceNote,
    );
  }

  Future<void> reactToComment({
    required int commentId,
    required String reaction,
  }) async {
    return await _apiService.reactToComment(
      commentId: commentId,
      reaction: reaction,
    );
  }

  Future<Map<String, dynamic>> editComment({
    required int commentId,
    required String newText,
  }) async {
    return await _apiService.editComment(
      commentId: commentId,
      newText: newText,
    );
  }

  Future<void> deleteComment(int commentId) async {
    return await _apiService.deleteComment(commentId);
  }
}
