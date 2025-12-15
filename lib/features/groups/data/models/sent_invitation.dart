import 'package:equatable/equatable.dart';
/// Model for a sent invitation to a group
class SentInvitation extends Equatable {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userGender;
  final String userPicture;
  final String userSubscribed;
  final String userVerified;
  const SentInvitation({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userGender,
    required this.userPicture,
    required this.userSubscribed,
    required this.userVerified,
  });
  factory SentInvitation.fromJson(Map<String, dynamic> json) {
    return SentInvitation(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userFirstname: json['user_firstname']?.toString() ?? '',
      userLastname: json['user_lastname']?.toString() ?? '',
      userGender: json['user_gender']?.toString() ?? '',
      userPicture: json['user_picture']?.toString() ?? '',
      userSubscribed: json['user_subscribed']?.toString() ?? '0',
      userVerified: json['user_verified']?.toString() ?? '0',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_firstname': userFirstname,
      'user_lastname': userLastname,
      'user_gender': userGender,
      'user_picture': userPicture,
      'user_subscribed': userSubscribed,
      'user_verified': userVerified,
    };
  }
  String get fullName => '$userFirstname $userLastname'.trim();
  bool get isVerified => userVerified == '1';
  bool get isSubscribed => userSubscribed == '1';
  @override
  List<Object?> get props => [
        userId,
        userName,
        userFirstname,
        userLastname,
        userGender,
        userPicture,
        userSubscribed,
        userVerified,
      ];
}
