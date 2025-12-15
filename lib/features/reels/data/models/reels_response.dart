import 'package:snginepro/features/feed/data/models/post.dart';
class ReelsResponse {
  ReelsResponse({
    required this.status,
    required this.reels,
    required this.sources,
    required this.pagination,
    required this.hasMore,
  });
  final String status;
  final List<Post> reels;
  final ReelsSources sources;
  final ReelsPagination pagination;
  final bool hasMore;
  bool get isSuccess => status == 'success';
  factory ReelsResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'error';
    final data = json['data'] as Map<String, dynamic>? ?? {};
    // Parse reels list
    final reelsList = <Post>[];
    final reelsData = data['reels'] as List?;
    if (reelsData != null) {
      for (final item in reelsData) {
        if (item is Map<String, dynamic>) {
          try {
            reelsList.add(Post.fromJson(item));
          } catch (e) {
            // Skip invalid reels
            continue;
          }
        }
      }
    }
    // Parse sources
    final sourcesData = data['sources'] as Map<String, dynamic>? ?? {};
    final sources = ReelsSources.fromJson(sourcesData);
    // Parse pagination
    final paginationData = data['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = ReelsPagination.fromJson(paginationData);
    // Parse has_more
    final hasMore = json['has_more'] as bool? ?? false;
    return ReelsResponse(
      status: status,
      reels: reelsList,
      sources: sources,
      pagination: pagination,
      hasMore: hasMore,
    );
  }
}
class ReelsSources {
  ReelsSources({
    required this.discover,
    required this.newsfeed,
  });
  final ReelsSourceInfo discover;
  final ReelsSourceInfo newsfeed;
  factory ReelsSources.fromJson(Map<String, dynamic> json) {
    final discoverData = json['discover'] as Map<String, dynamic>? ?? {};
    final newsfeedData = json['newsfeed'] as Map<String, dynamic>? ?? {};
    return ReelsSources(
      discover: ReelsSourceInfo.fromJson(discoverData),
      newsfeed: ReelsSourceInfo.fromJson(newsfeedData),
    );
  }
}
class ReelsSourceInfo {
  ReelsSourceInfo({
    required this.count,
    required this.hasMore,
    required this.limit,
    required this.offset,
  });
  final int count;
  final bool hasMore;
  final int limit;
  final int offset;
  factory ReelsSourceInfo.fromJson(Map<String, dynamic> json) {
    return ReelsSourceInfo(
      count: json['count'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      limit: json['limit'] as int? ?? 10,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
class ReelsPagination {
  ReelsPagination({
    required this.offset,
    required this.limit,
    required this.source,
  });
  final int offset;
  final int limit;
  final String source;
  factory ReelsPagination.fromJson(Map<String, dynamic> json) {
    return ReelsPagination(
      offset: json['offset'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
      source: json['source'] as String? ?? 'all',
    );
  }
}
