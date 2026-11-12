class StoryViewerModel {
  const StoryViewerModel({
    required this.userId,
    required this.userName,
    required this.userFullname,
    required this.userPicture,
    required this.userVerified,
    required this.userSubscribed,
    required this.time,
  });

  final int userId;
  final String userName;
  final String userFullname;
  final String userPicture;
  final bool userVerified;
  final bool userSubscribed;
  final String time;

  factory StoryViewerModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return StoryViewerModel(
      userId: _parseInt(user['user_id'] ?? json['user_id']),
      userName:
          user['user_name']?.toString() ?? json['user_name']?.toString() ?? '',
      userFullname:
          user['display_name']?.toString() ??
          user['user_fullname']?.toString() ??
          json['display_name']?.toString() ??
          json['user_fullname']?.toString() ??
          json['name']?.toString() ??
          '',
      userPicture:
          user['user_picture']?.toString() ??
          user['photo']?.toString() ??
          json['user_picture']?.toString() ??
          json['photo']?.toString() ??
          '',
      userVerified: _parseBool(user['user_verified'] ?? json['user_verified']),
      userSubscribed: _parseBool(
        user['user_subscribed'] ?? json['user_subscribed'],
      ),
      time:
          json['viewed_at_ago']?.toString() ??
          json['viewed_at']?.toString() ??
          json['time_ago']?.toString() ??
          json['time']?.toString() ??
          '',
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
