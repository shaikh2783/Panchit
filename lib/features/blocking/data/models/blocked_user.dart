class BlockedUser {
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? avatar;
  final bool verified;
  final bool subscribed;
  final bool blocked;

  BlockedUser({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.avatar,
    required this.verified,
    required this.subscribed,
    required this.blocked,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      avatar: (json['avatar']?.toString().isNotEmpty ?? false) ? json['avatar'].toString() : null,
      verified: json['verified'] == true,
      subscribed: json['subscribed'] == true,
      blocked: json['blocked'] == true,
    );
  }
}
