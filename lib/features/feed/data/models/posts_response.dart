import 'dart:collection';

import 'package:snginepro/features/feed/data/models/post.dart';

class PostsResponse {
  PostsResponse({
    required this.status,
    required List<Post> posts,
    required this.hasMore,
    this.message,
    Map<String, dynamic>? raw,
  })  : posts = UnmodifiableListView(posts),
        raw = raw != null ? UnmodifiableMapView(raw) : null;

  final String status;
  final UnmodifiableListView<Post> posts;
  final bool hasMore;
  final String? message;
  final Map<String, dynamic>? raw;

  bool get isSuccess => status.toLowerCase() == 'success';

  factory PostsResponse.fromJson(Map<String, dynamic> json, {int? requestedLimit}) {
    final status = (json['status'] as String?) ?? 'error';
    final data = json['data'];
    
    // Handle two different response formats:
    // 1. data is a list (newsfeed format)
    // 2. data is a map with 'posts' key (user posts format)
    final List<dynamic> postsData;
    if (data is List) {
      postsData = data;
    } else if (data is Map && data['posts'] is List) {
      postsData = data['posts'] as List;
    } else {
      postsData = [];
    }
    
    final posts = <Post>[];
    final skippedPosts = <Map<String, dynamic>>[];
    
    for (final itemData in postsData.whereType<Map<String, dynamic>>()) {
      try {
        final post = Post.fromJson(itemData);
        posts.add(post);
      } catch (e, stackTrace) {
        skippedPosts.add(itemData);
        // Continue processing other items instead of failing completely
      }
    }
    
    if (skippedPosts.isNotEmpty) {
    }
    
    // Calculate hasMore intelligently:
    // 1. First check if API provides has_more
    // 2. If API says false but we got posts < limit, try one more time to be sure
    // 3. If not, assume there's more unless we got 0 posts
    bool hasMore;
    if (json['has_more'] != null) {
      final apiHasMore = json['has_more'] == true ||
          json['has_more'] == '1' ||
          json['has_more'] == 1;
      
      // If API says no more but we got some posts, ignore it and try loading more
      // This handles backend bugs or misconfiguration
      if (!apiHasMore && posts.isNotEmpty) {
        hasMore = true;
      } else {
        hasMore = apiHasMore;
      }
    } else {
      // Always assume there's more unless we got 0 posts
      hasMore = posts.isNotEmpty;
    }

    return PostsResponse(
      status: status,
      posts: posts,
      hasMore: hasMore,
      message: json['message'] as String?,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
