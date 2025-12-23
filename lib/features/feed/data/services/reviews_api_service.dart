import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/feed/data/models/post_review.dart';
import 'package:snginepro/features/feed/data/models/post_review_stats.dart';
import 'package:snginepro/main.dart' show configCfgP;

class ReviewsApiService {
  ReviewsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<PostReview> addReview({
    required int postId,
    required int rating,
    String? review,
    List<Map<String, dynamic>>? photos,
  }) async {
    final body = <String, dynamic>{
      'post_id': postId,
      'rating': rating,
      if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
      if (photos != null && photos.isNotEmpty) 'photos': photos,
    };

    final resp = await _apiClient.post(
      configCfgP('posts_reviews_add'),
      body: body,
    );

    if (resp['data'] is Map<String, dynamic>) {
      return PostReview.fromJson(resp['data'] as Map<String, dynamic>);
    }
    throw Exception(resp['message'] ?? 'Failed to add review');
  }

  Future<List<PostReview>> getReviews({
    required int postId,
    int offset = 0,
  }) async {
    final resp = await _apiClient.get(
      configCfgP('posts_reviews'),
      queryParameters: {
        'post_id': postId.toString(),
        'offset': offset.toString(),
      },
    );

    final data = resp['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PostReview.fromJson)
          .toList();
    }
    return const [];
  }

  Future<ReviewStats?> getStats({required int postId}) async {
    final resp = await _apiClient.get(
      configCfgP('posts_reviews_stats'),
      queryParameters: {
        'post_id': postId.toString(),
      },
    );

    if (resp['data'] is Map<String, dynamic>) {
      return ReviewStats.fromJson(resp['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> deleteReview({required int reviewId}) async {
    final resp = await _apiClient.post(
      configCfgP('posts_reviews_delete'),
      body: {
        'review_id': reviewId,
      },
    );
    final success = resp['status'] == 'success' || resp['error'] == false;
    if (!success) {
      throw Exception(resp['message'] ?? 'Failed to delete review');
    }
  }

  Future<void> replyToReview({
    required int reviewId,
    required String reply,
  }) async {
    final resp = await _apiClient.post(
      configCfgP('posts_reviews_reply'),
      body: {
        'review_id': reviewId,
        'reply': reply,
      },
    );
    final success = resp['status'] == 'success' || resp['error'] == false;
    if (!success) {
      throw Exception(resp['message'] ?? 'Failed to add reply');
    }
  }
}
