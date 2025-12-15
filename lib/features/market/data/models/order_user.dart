import 'package:equatable/equatable.dart';
/// Order User Model - معلومات المستخدم (بائع أو مشتري)
class OrderUser extends Equatable {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userPicture;
  const OrderUser({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userPicture,
  });
  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userFirstname: json['user_firstname']?.toString() ?? '',
      userLastname: json['user_lastname']?.toString() ?? '',
      userPicture: json['user_picture']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_firstname': userFirstname,
      'user_lastname': userLastname,
      'user_picture': userPicture,
    };
  }
  String get fullName => '$userFirstname $userLastname'.trim();
  @override
  List<Object?> get props => [
        userId,
        userName,
        userFirstname,
        userLastname,
        userPicture,
      ];
}
