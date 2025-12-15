import 'package:equatable/equatable.dart';
/// Model for a friend who can be invited to a group
class InvitableFriend extends Equatable {
  final String userId;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userGender;
  final String userPicture;
  final String userSubscribed;
  final String userVerified;
  final String connection;
  final String nodeId;
  final bool isAdmin;
  const InvitableFriend({
    required this.userId,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userGender,
    required this.userPicture,
    required this.userSubscribed,
    required this.userVerified,
    required this.connection,
    required this.nodeId,
    this.isAdmin = false,
  });
  factory InvitableFriend.fromJson(Map<String, dynamic> json) {
    // Handle is_admin as boolean or string
    bool admin = false;
    if (json['is_admin'] != null) {
      if (json['is_admin'] is bool) {
        admin = json['is_admin'];
      } else {
        admin =
            json['is_admin'].toString() == '1' ||
            json['is_admin'].toString().toLowerCase() == 'true';
      }
    }
    return InvitableFriend(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userFirstname: json['user_firstname']?.toString() ?? '',
      userLastname: json['user_lastname']?.toString() ?? '',
      userGender: json['user_gender']?.toString() ?? '',
      userPicture: json['user_picture']?.toString() ?? '',
      userSubscribed: json['user_subscribed']?.toString() ?? '0',
      userVerified: json['user_verified']?.toString() ?? '0',
      connection: json['connection']?.toString() ?? '',
      nodeId: json['node_id']?.toString() ?? '',
      isAdmin: admin,
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
      'connection': connection,
      'node_id': nodeId,
      'is_admin': isAdmin,
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
    connection,
    nodeId,
    isAdmin,
  ];
}
