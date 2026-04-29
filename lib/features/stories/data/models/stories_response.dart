import 'package:snginepro/features/stories/data/models/story.dart';
import 'package:flutter/foundation.dart';

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
    int status = 0;
    final rawStatus = json['code'] ?? json['status'] ?? json['api_status'];
    if (rawStatus is int) {
      status = rawStatus;
    } else if (rawStatus is String) {
      final normalized = rawStatus.toLowerCase();
      if (normalized == 'success' || normalized == 'ok') {
        status = 200;
      } else {
        final parsed = int.tryParse(rawStatus);
        if (parsed != null) {
          status = parsed;
        }
      }
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

    if (status == 0 && (storiesList.isNotEmpty || json['data'] != null)) {
      status = 200;
    }

    return StoriesResponse(
      status: status,
      message: message,
      stories: storiesList,
    );
  }
}
