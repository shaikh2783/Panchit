import 'package:snginepro/features/stories/data/datasources/stories_api_service.dart';
import 'package:snginepro/features/stories/data/models/stories_response.dart';

class StoriesRepository {
  StoriesRepository(this._apiService);

  final StoriesApiService _apiService;

  Future<StoriesResponse> fetchStories({
    String format = 'both',
  }) {
    return _apiService.fetchStories(format: format);
  }

  Future<Map<String, dynamic>> createStory({
    String? imagePath,
    String? videoPath,
    String? text,
  }) {
    return _apiService.createStory(
      imagePath: imagePath,
      videoPath: videoPath,
      text: text,
    );
  }

  /// Delete a specific story by mediaId, or all stories if mediaId is null
  Future<Map<String, dynamic>> deleteStory({String? mediaId}) {
    return _apiService.deleteStory(mediaId: mediaId);
  }
}
