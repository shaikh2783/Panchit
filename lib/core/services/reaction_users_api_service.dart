import 'package:snginepro/core/models/reaction_user_model.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;
class ReactionUsersApiService {
  final ApiClient _apiClient;
  ReactionUsersApiService(this._apiClient);
  /// Get users who reacted to a post/photo/comment
  /// 
  /// [type] - 'post', 'photo', or 'comment'
  /// [id] - ID of the post/photo/comment
  /// [reaction] - Filter by reaction type: 'all', 'like', 'love', 'haha', 'yay', 'wow', 'sad', 'angry'
  /// [offset] - Pagination offset (default: 0)
  Future<ReactionUsersResponse> getReactionUsers({
    required String type,
    required int id,
    String reaction = 'all',
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        configCfgP('reactions_users'),
        queryParameters: {
          'type': type,
          'id': id.toString(),
          'reaction': reaction,
          'offset': offset.toString(),
        },
      );
      if (response['status'] == 'success') {
        return ReactionUsersResponse.fromJson(response);
      } else {
        throw Exception(response['message'] ?? 'Failed to load reaction users');
      }
    } catch (e) {
      rethrow;
    }
  }
  /// Get users who reacted to a post
  Future<ReactionUsersResponse> getPostReactionUsers({
    required int postId,
    String reaction = 'all',
    int offset = 0,
  }) {
    return getReactionUsers(
      type: 'post',
      id: postId,
      reaction: reaction,
      offset: offset,
    );
  }
  /// Get users who reacted to a photo
  Future<ReactionUsersResponse> getPhotoReactionUsers({
    required int photoId,
    String reaction = 'all',
    int offset = 0,
  }) {
    return getReactionUsers(
      type: 'photo',
      id: photoId,
      reaction: reaction,
      offset: offset,
    );
  }
  /// Get users who reacted to a comment
  Future<ReactionUsersResponse> getCommentReactionUsers({
    required int commentId,
    String reaction = 'all',
    int offset = 0,
  }) {
    return getReactionUsers(
      type: 'comment',
      id: commentId,
      reaction: reaction,
      offset: offset,
    );
  }
}
