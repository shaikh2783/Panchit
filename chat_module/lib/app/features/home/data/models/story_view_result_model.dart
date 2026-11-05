class StoryViewResultModel {
  const StoryViewResultModel({
    required this.storyId,
    required this.storyMediaId,
    required this.recorded,
    required this.alreadyViewed,
    required this.ownerView,
    required this.viewsCount,
    required this.reactionsCount,
  });

  final int storyId;
  final int storyMediaId;
  final bool recorded;
  final bool alreadyViewed;
  final bool ownerView;
  final int viewsCount;
  final int reactionsCount;

  factory StoryViewResultModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return StoryViewResultModel(
      storyId: _parseInt(data['story_id']),
      storyMediaId: _parseInt(data['story_media_id']),
      recorded: _parseBool(data['recorded']),
      alreadyViewed: _parseBool(data['already_viewed']),
      ownerView: _parseBool(data['owner_view']),
      viewsCount: _parseInt(data['views_count']),
      reactionsCount: _parseInt(data['reactions_count']),
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
