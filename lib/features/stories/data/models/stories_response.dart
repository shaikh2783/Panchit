import 'package:snginepro/features/stories/data/models/story.dart';
class StoriesResponse {
  StoriesResponse({
    required this.status,
    this.message,
    required this.stories,
  });
  final int status;
  final String? message;
  final List<Story> stories;
  bool get isSuccess => status == 200;
  factory StoriesResponse.fromJson(Map<String, dynamic> json) {
    // Handle status - can be String ("success") or int (200)
    int status = 0;
    final statusValue = json['code'] ?? json['status'];
    if (statusValue is int) {
      status = statusValue;
    } else if (statusValue is String) {
      // If status is "success", treat as 200
      status = statusValue == 'success' ? 200 : 0;
    }
    final message = json['message'] as String?;
    final storiesList = <Story>[];
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      // Handle nested stories structure: {data: {stories: [...]}}
      final stories = data['stories'];
      if (stories is List) {
        for (final item in stories) {
          if (item is Map<String, dynamic>) {
            try {
              storiesList.add(Story.fromJson(item));
            } catch (e) {
              continue;
            }
          }
        }
      }
    } else if (data is List) {
      // Handle direct list structure: {data: [...]}
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            storiesList.add(Story.fromJson(item));
          } catch (e) {
            continue;
          }
        }
      }
    }
    return StoriesResponse(
      status: status,
      message: message,
      stories: storiesList,
    );
  }
}
