import 'package:snginepro/features/feed/data/models/post_review.dart';
import 'package:snginepro/features/feed/data/models/post_review_stats.dart';
import 'package:snginepro/features/feed/data/services/reviews_api_service.dart';

class ReviewsRepository {
  ReviewsRepository(this._service);

  final ReviewsApiService _service;

  Future<PostReview> addReview({
    required int postId,
    required int rating,
    String? review,
    List<Map<String, dynamic>>? photos,
  }) {
    return _service.addReview(
      postId: postId,
      rating: rating,
      review: review,
      photos: photos,
    );
  }

  Future<List<PostReview>> getReviews({
    required int postId,
    int offset = 0,
  }) {
    return _service.getReviews(postId: postId, offset: offset);
  }

  Future<ReviewStats?> getStats({required int postId}) {
    return _service.getStats(postId: postId);
  }

  Future<void> deleteReview({required int reviewId}) {
    return _service.deleteReview(reviewId: reviewId);
  }

  Future<void> replyToReview({required int reviewId, required String reply}) {
    return _service.replyToReview(reviewId: reviewId, reply: reply);
  }
}
