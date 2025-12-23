/// نموذج مشرف المجموعة
class GroupAdmin {
  final int userId;
  final String username;
  final String firstname;
  final String lastname;
  final String fullname;
  final String picture;
  final bool verified;
  final bool? subscribed;

  GroupAdmin({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    required this.picture,
    required this.verified,
    this.subscribed,
  });

  factory GroupAdmin.fromJson(Map<String, dynamic> json) {
    return GroupAdmin(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      fullname: json['fullname'] ?? '',
      picture: json['picture'] ?? '',
      verified: json['verified'] == true || json['verified'] == 1,
      subscribed: json['subscribed'] == true || json['subscribed'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'fullname': fullname,
      'picture': picture,
      'verified': verified,
      if (subscribed != null) 'subscribed': subscribed,
    };
  }
}
