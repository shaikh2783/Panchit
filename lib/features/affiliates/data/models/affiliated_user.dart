class AffiliatedUser {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userPicture;
  final String userEmail;
  final String userRegistered;
  final String connectionDate;
  final bool isActive;
  final int referrerLevel;

  AffiliatedUser({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userPicture,
    required this.userEmail,
    required this.userRegistered,
    required this.connectionDate,
    required this.isActive,
    required this.referrerLevel,
  });

  factory AffiliatedUser.fromJson(Map<String, dynamic> json) {
    return AffiliatedUser(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userFirstname: json['user_firstname'] ?? '',
      userLastname: json['user_lastname'] ?? '',
      userPicture: json['user_picture'] ?? '',
      userEmail: json['user_email'] ?? '',
      userRegistered: json['user_registered'] ?? '',
      connectionDate: json['connection_date'] ?? '',
      isActive: json['is_active'] ?? false,
      referrerLevel: json['referrer_level'] ?? 1,
    );
  }

  String get fullName => '$userFirstname $userLastname'.trim();

  String get levelLabel {
    switch (referrerLevel) {
      case 1:
        return 'المستوى 1 (مباشر)';
      case 2:
        return 'المستوى 2';
      case 3:
        return 'المستوى 3';
      case 4:
        return 'المستوى 4';
      case 5:
        return 'المستوى 5';
      default:
        return 'مستوى ${referrerLevel}';
    }
  }
}
