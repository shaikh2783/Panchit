class ReactionUser {
  final String userId;
  final String userName;
  final String firstname;
  final String lastname;
  final String fullname;
  final String gender;
  final String picture;
  final bool verified;
  final bool subscribed;
  final String reaction;
  final String connection;
  final int mutualFriendsCount;
  ReactionUser({
    required this.userId,
    required this.userName,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    required this.gender,
    required this.picture,
    required this.verified,
    required this.subscribed,
    required this.reaction,
    required this.connection,
    required this.mutualFriendsCount,
  });
  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? '',
      firstname: json['user_firstname'] ?? '',
      lastname: json['user_lastname'] ?? '',
      fullname: json['user_fullname'] ?? '',
      gender: json['user_gender'] ?? 'male',
      picture: json['user_picture'] ?? '',
      verified: json['user_verified'] == true,
      subscribed: json['user_subscribed'] == true,
      reaction: json['reaction'] ?? 'like',
      connection: json['connection'] ?? 'none',
      mutualFriendsCount: json['mutual_friends_count'] ?? 0,
    );
  }
  bool get isFriend => connection == 'friend';
  bool get isFollowing => connection == 'following';
  bool get isFollower => connection == 'follower';
  bool get hasRequest => connection == 'request';
  bool get noConnection => connection == 'none';
}
class ReactionUsersResponse {
  final List<ReactionUser> users;
  final int total;
  final int offset;
  final bool hasMore;
  final String reactionFilter;
  final Map<String, int> reactionStats;
  ReactionUsersResponse({
    required this.users,
    required this.total,
    required this.offset,
    required this.hasMore,
    required this.reactionFilter,
    required this.reactionStats,
  });
  factory ReactionUsersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ReactionUsersResponse(
      users: (data['users'] as List?)
              ?.map((u) => ReactionUser.fromJson(u))
              .toList() ??
          [],
      total: data['total'] ?? 0,
      offset: data['offset'] ?? 0,
      hasMore: data['has_more'] == true,
      reactionFilter: data['reaction_filter'] ?? 'all',
      reactionStats: Map<String, int>.from(data['reaction_stats'] ?? {}),
    );
  }
}
