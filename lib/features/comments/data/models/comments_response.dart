import 'comment.dart';
class CommentsResponse {
  final List<CommentModel> comments;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  CommentsResponse({
    required this.comments,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });
  factory CommentsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final commentsList = data['comments'] as List? ?? [];
    return CommentsResponse(
      comments: commentsList
          .map((comment) => CommentModel.fromJson(comment as Map<String, dynamic>))
          .toList(),
      total: data['total'] is int 
          ? data['total'] 
          : int.tryParse(data['total']?.toString() ?? '0') ?? 0,
      offset: data['offset'] is int 
          ? data['offset'] 
          : int.tryParse(data['offset']?.toString() ?? '0') ?? 0,
      limit: data['limit'] is int 
          ? data['limit'] 
          : int.tryParse(data['limit']?.toString() ?? '0') ?? 20,
      hasMore: data['has_more'] == true || 
               data['has_more'] == 1 ||
               data['has_more']?.toString() == '1',
    );
  }
}
class RepliesResponse {
  final List<CommentModel> replies;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;
  RepliesResponse({
    required this.replies,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });
  factory RepliesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final repliesList = data['replies'] as List? ?? [];
    return RepliesResponse(
      replies: repliesList
          .map((reply) => CommentModel.fromJson(reply as Map<String, dynamic>))
          .toList(),
      total: data['total'] is int 
          ? data['total'] 
          : int.tryParse(data['total']?.toString() ?? '0') ?? 0,
      offset: data['offset'] is int 
          ? data['offset'] 
          : int.tryParse(data['offset']?.toString() ?? '0') ?? 0,
      limit: data['limit'] is int 
          ? data['limit'] 
          : int.tryParse(data['limit']?.toString() ?? '0') ?? 10,
      hasMore: data['has_more'] == true || 
               data['has_more'] == 1 ||
               data['has_more']?.toString() == '1',
    );
  }
}
