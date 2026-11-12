import 'story_viewer_model.dart';

class StoryViewersResponseModel {
  const StoryViewersResponseModel({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<StoryViewerModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory StoryViewersResponseModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final rawItems = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
    return StoryViewersResponseModel(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                StoryViewerModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: data['next_offset'] == null
          ? null
          : _parseInt(data['next_offset']),
      hasMore: _parseBool(data['has_more']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}
