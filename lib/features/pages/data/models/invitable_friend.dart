class InvitableFriend {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userGender;
  final String userPicture;
  final bool userSubscribed;
  final bool userVerified;
  final String connection;
  final String? nodeId;
  final bool isAdmin;

  InvitableFriend({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userGender,
    required this.userPicture,
    required this.userSubscribed,
    required this.userVerified,
    required this.connection,
    required this.nodeId,
    required this.isAdmin,
  });

  String get fullName =>
      [userFirstname, userLastname].where((s) => s.isNotEmpty).join(' ').trim();

  factory InvitableFriend.fromJson(Map<String, dynamic> json) {
    return InvitableFriend(
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      userName: (json['user_name'] ?? json['username'] ?? '') as String,
      userFirstname: (json['user_firstname'] ?? json['firstname'] ?? '') as String,
      userLastname: (json['user_lastname'] ?? json['lastname'] ?? '') as String,
      userGender: (json['user_gender'] ?? json['gender'] ?? '') as String,
      userPicture: (json['user_picture'] ?? json['picture'] ?? '') as String,
      userSubscribed: (json['user_subscribed'] ?? json['subscribed'] ?? false) as bool,
      userVerified: (json['user_verified'] ?? json['verified'] ?? false) as bool,
      connection: (json['connection'] ?? '') as String,
      nodeId: json['node_id']?.toString(),
      isAdmin: (json['is_admin'] ?? false) as bool,
    );
  }
}
