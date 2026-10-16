import 'story_reaction_model.dart';

class StoryReactionsResponseModel {
  const StoryReactionsResponseModel({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
    required this.hasMore,
  });

  final List<StoryReactionModel> items;
  final int count;
  final int offset;
  final int? nextOffset;
  final bool hasMore;

  factory StoryReactionsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => StoryReactionModel.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
        : const <StoryReactionModel>[];

    return StoryReactionsResponseModel(
      items: items,
      count: _asInt(data['count']),
      offset: _asInt(data['offset']),
      nextOffset: _asNullableInt(data['next_offset']),
      hasMore: _asBool(data['has_more']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse('$value');
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
}
