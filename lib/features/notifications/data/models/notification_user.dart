class NotificationUser {
  final int id;
  final String name;
  final String picture;
  final bool verified;
  final String type;
  NotificationUser({
    required this.id,
    required this.name,
    required this.picture,
    required this.verified,
    required this.type,
  });
  factory NotificationUser.fromJson(Map<String, dynamic> json) {
    return NotificationUser(
      id: json['id'] as int,
      name: json['name'] as String,
      picture: json['picture'] as String,
      verified: json['verified'] as bool? ?? false,
      type: json['type'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'picture': picture,
      'verified': verified,
      'type': type,
    };
  }
}
