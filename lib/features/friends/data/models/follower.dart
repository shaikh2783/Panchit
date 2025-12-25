class Follower {
  final int userId;
  final String userName;
  final String name;
  final String userPicture;
  final bool isVerified;
  final bool isSubscribed;
  final String connection;
  final bool iFollow;
  final int mutualFriendsCount;
  final bool isOnline;
  final String? lastSeen;

  Follower({
    required this.userId,
    required this.userName,
    required this.name,
    required this.userPicture,
    required this.isVerified,
    required this.isSubscribed,
    required this.connection,
    required this.iFollow,
    required this.mutualFriendsCount,
    required this.isOnline,
    this.lastSeen,
  });

  factory Follower.fromJson(Map<String, dynamic> json) {
    return Follower(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      name: json['name'] ?? '',
      userPicture: json['user_picture'] ?? '',
      isVerified: json['user_verified'] ?? false,
      isSubscribed: json['user_subscribed'] ?? false,
      connection: json['connection'] ?? '',
      iFollow: json['i_follow'] ?? false,
      mutualFriendsCount: json['mutual_friends_count'] ?? 0,
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'],
    );
  }
}
