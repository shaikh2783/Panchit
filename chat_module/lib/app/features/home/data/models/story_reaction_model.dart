class StoryReactionModel {
  const StoryReactionModel({
    required this.reactionId,
    required this.reactionKey,
    required this.reactionTitle,
    required this.reactionColor,
    required this.reactionImageUrl,
    required this.userId,
    required this.userName,
    required this.userFullname,
    required this.userPicture,
    required this.userVerified,
    required this.time,
  });

  final int reactionId;
  final String reactionKey;
  final String reactionTitle;
  final String reactionColor;
  final String reactionImageUrl;
  final int userId;
  final String userName;
  final String userFullname;
  final String userPicture;
  final bool userVerified;
  final String time;

  factory StoryReactionModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final reaction = _asMap(json['reaction']);

    return StoryReactionModel(
      reactionId: _asInt(
        json['reaction_id'] ?? json['story_reaction_id'] ?? reaction['id'],
      ),
      reactionKey: _asString(
        json['reaction_key'] ??
            json['reaction'] ??
            reaction['key'] ??
            reaction['reaction'],
      ),
      reactionTitle: _asString(
        json['reaction_title'] ?? reaction['title'] ?? reaction['name'],
      ),
      reactionColor: _asString(
        json['reaction_color'] ?? reaction['color'] ?? reaction['hex'],
      ),
      reactionImageUrl: _asString(
        json['reaction_image_url'] ??
            json['reaction_icon_url'] ??
            reaction['image_url'] ??
            reaction['icon_url'] ??
            reaction['image'],
      ),
      userId: _asInt(json['user_id'] ?? user['user_id']),
      userName: _asString(json['user_name'] ?? user['user_name']),
      userFullname: _asString(
        json['user_fullname'] ??
            json['display_name'] ??
            user['display_name'] ??
            user['user_fullname'],
      ),
      userPicture: _asString(
        json['user_picture'] ??
            json['photo'] ??
            user['photo'] ??
            user['user_picture'],
      ),
      userVerified: _asBool(json['user_verified'] ?? user['user_verified']),
      time: _asString(
        json['created_at_ago'] ??
            json['time_ago'] ??
            json['reacted_at'] ??
            json['created_at'] ??
            json['time'] ??
            reaction['time'],
      ),
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

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
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
