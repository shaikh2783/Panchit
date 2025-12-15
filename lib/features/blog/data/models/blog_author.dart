class BlogAuthor {
  final int userId;
  final String userName;
  final String userPicture;
  const BlogAuthor({
    required this.userId,
    required this.userName,
    required this.userPicture,
  });
  factory BlogAuthor.fromJson(Map<String, dynamic> json) {
    return BlogAuthor(
      userId: json['user_id'] is String
          ? int.tryParse(json['user_id']) ?? 0
          : (json['user_id'] ?? 0) as int,
      userName: (json['user_name'] ?? '').toString(),
      userPicture: (json['user_picture'] ?? '').toString(),
    );
  }
}
