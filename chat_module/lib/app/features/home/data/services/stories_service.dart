import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_endpoints.dart';
import '../models/stories_response_model.dart';
import '../models/story_reactions_response_model.dart';
import '../models/story_view_result_model.dart';
import '../models/story_viewers_response_model.dart';

class StoriesService {
  StoriesService(this._apiClient);

  final ChatModuleApiClient _apiClient;

  Future<StoriesResponseModel> loadStories() async {
    final response = await _apiClient.get(
      ApiEndpoints.storiesList,
      authenticated: true,
    );
    return StoriesResponseModel.fromJson(response);
  }

  Future<void> replyToStory({
    required int storyId,
    int? storyMediaId,
    required String message,
  }) async {
    await _apiClient.post(
      ApiEndpoints.storiesReply,
      authenticated: true,
      body: <String, dynamic>{
        'story_id': storyId,
        if ((storyMediaId ?? 0) > 0) 'story_media_id': storyMediaId,
        'message': message.trim(),
      },
    );
  }

  Future<void> reactToStory({
    required int storyId,
    int? storyMediaId,
    required String reactionKey,
  }) async {
    await _apiClient.post(
      ApiEndpoints.storiesReact,
      authenticated: true,
      body: <String, dynamic>{
        'story_id': storyId,
        if ((storyMediaId ?? 0) > 0) 'story_media_id': storyMediaId,
        'reaction': reactionKey,
      },
    );
  }

  Future<StoryViewResultModel> markStoryViewed({
    required int storyId,
    required int storyMediaId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.storiesView,
      authenticated: true,
      body: <String, dynamic>{
        'story_id': storyId,
        'story_media_id': storyMediaId,
      },
    );
    return StoryViewResultModel.fromJson(response);
  }

  Future<StoryViewersResponseModel> fetchStoryViewers({
    required int storyId,
    required int storyMediaId,
    int? offset,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.storiesViewers,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'story_id': storyId,
        'story_media_id': storyMediaId,
        ...?_offsetQuery(offset),
      },
    );
    return StoryViewersResponseModel.fromJson(response);
  }

  Future<StoryReactionsResponseModel> fetchStoryReactions({
    required int storyId,
    required int storyMediaId,
    int? offset,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.storiesReactions,
      authenticated: true,
      queryParameters: <String, dynamic>{
        'story_id': storyId,
        'story_media_id': storyMediaId,
        ...?_offsetQuery(offset),
      },
    );
    return StoryReactionsResponseModel.fromJson(response);
  }

  Future<void> publishStory({
    required String message,
    required List<String> photos,
    required List<String> videos,
  }) async {
    await _apiClient.post(
      ApiEndpoints.storiesPublish,
      authenticated: true,
      body: <String, dynamic>{
        'message': message.trim(),
        'photos': photos
            .map((source) => <String, dynamic>{'source': source})
            .toList(),
        'videos': videos
            .map((source) => <String, dynamic>{'source': source})
            .toList(),
      },
    );
  }

  Map<String, dynamic>? _offsetQuery(int? offset) {
    if (offset == null) {
      return null;
    }
    return <String, dynamic>{'offset': offset};
  }
}
