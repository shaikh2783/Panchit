/// نموذج عضو المجموعة
class GroupMember {
  final int userId;
  final String username;
  final String firstname;
  final String lastname;
  final String fullname;
  final String picture;
  final bool verified;
  final bool subscribed;
  final bool isApproved;
  final bool isAdmin;

  GroupMember({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    required this.picture,
    required this.verified,
    required this.subscribed,
    required this.isApproved,
    required this.isAdmin,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      fullname: json['fullname'] ?? '${json['firstname'] ?? ''} ${json['lastname'] ?? ''}'.trim(),
      picture: json['picture'] ?? '',
      verified: json['verified'] == true || json['verified'] == 1,
      subscribed: json['subscribed'] == true || json['subscribed'] == 1,
      isApproved: json['is_approved'] == true || json['is_approved'] == 1,
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
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
      'subscribed': subscribed,
      'is_approved': isApproved,
      'is_admin': isAdmin,
    };
  }
}

/// استجابة قائمة الأعضاء
class GroupMembersResponse {
  final List<GroupMember> members;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  GroupMembersResponse({
    required this.members,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory GroupMembersResponse.fromJson(Map<String, dynamic> json) {
    // إذا كان json يحتوي على 'data'، استخرجها، وإلا استخدم json مباشرة
    final data = json.containsKey('data') ? json['data'] as Map<String, dynamic> : json;
    final membersList = data['members'] as List<dynamic>? ?? [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

    return GroupMembersResponse(
      members: membersList.map((m) => GroupMember.fromJson(m as Map<String, dynamic>)).toList(),
      total: pagination['total'] ?? 0,
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      totalPages: pagination['pages'] ?? 0,
    );
  }
}
