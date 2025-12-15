import 'package:equatable/equatable.dart';
/// Model for a received group invitation
class ReceivedInvitation extends Equatable {
  final String groupId;
  final String groupName;
  final String groupTitle;
  final String groupPicture;
  final String groupPrivacy;
  final String inviterId;
  final String inviterUsername;
  final String inviterFirstname;
  final String inviterLastname;
  final String inviterPicture;
  const ReceivedInvitation({
    required this.groupId,
    required this.groupName,
    required this.groupTitle,
    required this.groupPicture,
    required this.groupPrivacy,
    required this.inviterId,
    required this.inviterUsername,
    required this.inviterFirstname,
    required this.inviterLastname,
    required this.inviterPicture,
  });
  factory ReceivedInvitation.fromJson(Map<String, dynamic> json) {
    return ReceivedInvitation(
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      groupTitle: json['group_title']?.toString() ?? '',
      groupPicture: json['group_picture']?.toString() ?? '',
      groupPrivacy: json['group_privacy']?.toString() ?? '',
      inviterId: json['inviter_id']?.toString() ?? '',
      inviterUsername: json['inviter_username']?.toString() ?? '',
      inviterFirstname: json['inviter_firstname']?.toString() ?? '',
      inviterLastname: json['inviter_lastname']?.toString() ?? '',
      inviterPicture: json['inviter_picture']?.toString() ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'group_title': groupTitle,
      'group_picture': groupPicture,
      'group_privacy': groupPrivacy,
      'inviter_id': inviterId,
      'inviter_username': inviterUsername,
      'inviter_firstname': inviterFirstname,
      'inviter_lastname': inviterLastname,
      'inviter_picture': inviterPicture,
    };
  }
  String get inviterFullName => '$inviterFirstname $inviterLastname'.trim();
  bool get isPublicGroup => groupPrivacy == 'public';
  bool get isPrivateGroup => groupPrivacy == 'private';
  @override
  List<Object?> get props => [
        groupId,
        groupName,
        groupTitle,
        groupPicture,
        groupPrivacy,
        inviterId,
        inviterUsername,
        inviterFirstname,
        inviterLastname,
        inviterPicture,
      ];
}
