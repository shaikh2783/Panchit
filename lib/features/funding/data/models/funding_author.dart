class FundingAuthor {
  final String userId;
  final String userName;
  final String? userPicture;
  FundingAuthor({
    required this.userId,
    required this.userName,
    this.userPicture,
  });
  factory FundingAuthor.fromJson(Map<String, dynamic> json) {
    return FundingAuthor(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userPicture: json['user_picture']?.toString(),
    );
  }
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        if (userPicture != null) 'user_picture': userPicture,
      };
}
