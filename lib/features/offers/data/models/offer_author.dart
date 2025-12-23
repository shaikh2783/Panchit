class OfferAuthor {
  final String userId;
  final String userName;
  final String? userPicture;

  OfferAuthor({
    required this.userId,
    required this.userName,
    this.userPicture,
  });

  factory OfferAuthor.fromJson(Map<String, dynamic> json) => OfferAuthor(
        userId: json['user_id']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? '',
        userPicture: json['user_picture']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        if (userPicture != null) 'user_picture': userPicture,
      };
}
