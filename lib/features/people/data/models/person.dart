class Person {
  const Person({
    required this.userId,
    required this.fullName,
    required this.userName,
    required this.picture,
    this.verified = false,
    this.subscribed = false,
    this.isOnline = false,
    this.lastSeen,
  });

  final String userId;
  final String fullName;
  final String userName;
  final String picture;
  final bool verified;
  final bool subscribed;
  final bool isOnline;
  final String? lastSeen;

  factory Person.fromJson(Map<String, dynamic> json) {
    String _string(Object? v) => v == null ? '' : v.toString();
    bool _bool(Object? v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return Person(
      userId: _string(json['user_id']).isNotEmpty ? _string(json['user_id']) : _string(json['id']),
      fullName: _string(json['user_fullname']).isNotEmpty ? _string(json['user_fullname']) : _string(json['full_name']),
      userName: _string(json['user_name']).isNotEmpty ? _string(json['user_name']) : _string(json['username']),
      picture: _string(json['user_picture']).isNotEmpty ? _string(json['user_picture']) : _string(json['picture']),
      verified: _bool(json['user_verified'] ?? json['verified']),
      subscribed: _bool(json['user_subscribed'] ?? json['subscribed']),
      isOnline: _bool(json['user_is_online'] ?? json['is_online']),
      lastSeen: json['user_last_seen']?.toString() ?? json['last_seen']?.toString(),
    );
  }
}
