class JobAuthor {
  final int userId;
  final String userName;
  final String userPicture;
  const JobAuthor({
    required this.userId,
    required this.userName,
    required this.userPicture,
  });
  factory JobAuthor.fromJson(Map<String, dynamic> json) {
    return JobAuthor(
      userId: json['user_id'] is String
          ? int.tryParse(json['user_id']) ?? 0
          : (json['user_id'] ?? 0) as int,
      userName: (json['user_name'] ?? '').toString(),
      userPicture: (json['user_picture'] ?? '').toString(),
    );
  }
}
