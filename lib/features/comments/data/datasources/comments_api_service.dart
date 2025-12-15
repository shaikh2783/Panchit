import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'dart:io';
import '../models/comment.dart';
import '../models/comments_response.dart';
class CommentsApiService {
  final ApiClient _client;
  CommentsApiService(this._client);
  /// Get comments for a post with pagination
  Future<CommentsResponse> getPostComments(
    int postId, {
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        configCfgP('posts_comments'),
        queryParameters: {
          'post_id': postId.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success') {
        return CommentsResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch comments');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Create a new comment on a post
  Future<CommentModel> createComment({
    required int postId,
    required String text,
    String? image,
    String? voiceNote,
  }) async {
    try {
      final response = await _client.post(
        configCfgP('posts_comment'),
        body: {
          'post_id': postId,
          'text': text,
          'image': image ?? '',
          'voice_note': voiceNote ?? '',
        },
      );
      if (response['error'] == true) {
        throw Exception(response['message'] ?? 'Failed to create comment');
      }
      return CommentModel.fromJson(response['comment']);
    } catch (e) {
      rethrow;
    }
  }
  /// Get replies for a comment with pagination
  Future<RepliesResponse> getCommentReplies(
    int commentId, {
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        configCfgP('comments_replies'),
        queryParameters: {
          'comment_id': commentId.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );
      if (response['status'] == 'success') {
        return RepliesResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch replies');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Create a reply to a comment
  Future<CommentModel> createReply({
    required int commentId,
    required String text,
    String? image,
    String? voiceNote,
  }) async {
    try {
      final response = await _client.post(
        configCfgP('comments_reply'),
        body: {
          'comment_id': commentId,
          'text': text,
          'image': image ?? '',
          'voice_note': voiceNote ?? '',
        },
      );
      if (response['status'] == 'success') {
        return CommentModel.fromJson(response['data']['reply']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create reply');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// React to a comment (like, love, haha, yay, wow, sad, angry, remove)
  Future<void> reactToComment({
    required int commentId,
    required String reaction,
  }) async {
    try {
      final response = await _client.post(
        configCfgP('comments_react'),
        body: {
          'comment_id': commentId,
          'reaction': reaction,
        },
      );
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to react to comment');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Edit an existing comment
  Future<Map<String, dynamic>> editComment({
    required int commentId,
    required String newText,
  }) async {
    try {
      final response = await _client.post(
        configCfgP('comments_edit'),
        body: {
          'comment_id': commentId,
          'text': newText,
        },
      );
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to edit comment');
      }
      return response['data']['comment'];
    } catch (e) {
      rethrow;
    }
  }
  /// Delete a comment
  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _client.post(
        configCfgP('comments_delete'),
        body: {
          'comment_id': commentId,
        },
      );
      if (response['status'] != 'success') {
        throw Exception(response['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Upload image file and get the path
  Future<String> uploadImage(File imageFile) async {
    try {
      final response = await _client.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'photo'},
        filePath: imageFile.path,
        fileFieldName: 'file',
      );
      if (response['status'] == 'success') {
        // Return the source path (not the full URL)
        return response['data']['source'] ?? '';
      } else {
        throw Exception(response['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Upload audio file and get the path
  Future<String> uploadAudio(File audioFile) async {
    try {
      final response = await _client.multipartPost(
        configCfgP('file_upload'),
        body: {'type': 'audio'},
        filePath: audioFile.path,
        fileFieldName: 'file',
      );
      if (response['status'] == 'success') {
        // Return the source path (not the full URL)
        return response['data']['source'] ?? '';
      } else {
        throw Exception(response['message'] ?? 'Failed to upload audio');
      }
    } catch (e) {
      rethrow;
    }
  }
}
