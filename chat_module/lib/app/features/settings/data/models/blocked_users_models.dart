class BlockedUsersResponse {
  const BlockedUsersResponse({
    required this.items,
    required this.count,
    required this.offset,
    required this.nextOffset,
  });

  final List<BlockedUserModel> items;
  final int count;
  final int offset;
  final int? nextOffset;

  bool get hasMore => nextOffset != null;

  factory BlockedUsersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final rawItems = _normalizeItems(data['items']);
    return BlockedUsersResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                BlockedUserModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      count: _parseInt(data['count']),
      offset: _parseInt(data['offset']),
      nextOffset: _parseNullableInt(data['next_offset']),
    );
  }

  static List<dynamic> _normalizeItems(dynamic value) {
    final items = <Map<String, dynamic>>[];

    void collect(dynamic candidate) {
      if (candidate is List) {
        for (final item in candidate) {
          collect(item);
        }
        return;
      }
      if (candidate is! Map) {
        return;
      }

      final map = Map<String, dynamic>.from(candidate);
      final userId = _parseInt(map['user_id']);
      final userName = map['user_name']?.toString().trim() ?? '';
      if (userId > 0 || userName.isNotEmpty) {
        items.add(map);
        return;
      }

      if (map.containsKey('data')) {
        collect(map['data']);
        return;
      }
      for (final nested in map.values) {
        collect(nested);
      }
    }

    collect(value);
    return items;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}

class BlockedUserModel {
  const BlockedUserModel({
    required this.id,
    required this.userName,
    required this.displayName,
    required this.pictureUrl,
    required this.profileUrl,
    required this.blocked,
  });

  final int id;
  final String userName;
  final String displayName;
  final String pictureUrl;
  final String profileUrl;
  final bool blocked;

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: _parseInt(json['user_id']),
      userName: json['user_name']?.toString().trim() ?? '',
      displayName:
          json['display_name']?.toString().trim() ??
          json['user_name']?.toString().trim() ??
          '',
      pictureUrl: json['user_picture']?.toString().trim() ?? '',
      profileUrl: json['profile_url']?.toString().trim() ?? '',
      blocked: _parseBool(json['blocked']),
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
