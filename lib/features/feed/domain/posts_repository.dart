import 'dart:io';
import 'package:snginepro/features/feed/data/datasources/posts_api_service.dart';
import 'package:snginepro/features/feed/data/models/posts_response.dart';
import 'package:snginepro/features/feed/data/models/story.dart';
class PostsRepository {
  PostsRepository(this._apiService);
  final PostsApiService _apiService;
  Future<PostsResponse> fetchNewsfeed({
    int limit = 10,
    int offset = 0,
  }) {
    return _apiService.fetchNewsfeed(limit: limit, offset: offset);
  }
  Future<PostsResponse> fetchUserPosts({
    required int userId,
    int limit = 20,
    int offset = 0,
  }) {
    return _apiService.fetchUserPosts(userId: userId, limit: limit, offset: offset);
  }
  Future<Map<String, dynamic>> fetchPost(int postId) {
    return _apiService.fetchPost(postId);
  }
  Future<void> reactToPost(int postId, String reaction) {
    return _apiService.reactToPost(postId, reaction);
  }
  Future<List<Story>> fetchStories() {
    return _apiService.fetchStories();
  }
  Future<String?> uploadPhoto(File photo) {
    return _apiService.uploadPhoto(photo);
  }
  Future<void> createPost(
    String message, {
    List<String>? photoSources,
    int? coloredPattern,
    String? feelingAction,
    String? feelingValue,
  }) {
    return _apiService.createPost(
      message,
      photoSources: photoSources,
      coloredPattern: coloredPattern,
      feelingAction: feelingAction,
      feelingValue: feelingValue,
    );
  }
  Future<void> createStory(String message, {List<String>? photoSources}) {
    // This will be implemented in the next steps
    return Future.value();
  }
}
