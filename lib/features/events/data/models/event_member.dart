import 'package:equatable/equatable.dart';

/// نموذج عضو الفعالية (Event Member)
class EventMember extends Equatable {
  final String userId;
  final String userName;
  final String? firstName;
  final String? lastName;
  final String? userPicture;
  final String membershipStatus; // going, interested, invited
  final DateTime joinedAt;
  final bool isAdmin;

  const EventMember({
    required this.userId,
    required this.userName,
    this.firstName,
    this.lastName,
    this.userPicture,
    required this.membershipStatus,
    required this.joinedAt,
    required this.isAdmin,
  });

  factory EventMember.fromJson(Map<String, dynamic> json) {
    // معالجة user_picture لتجنب تكرار base URL
    String? picture = json['user_picture']?.toString();
    if (picture != null && picture.isNotEmpty) {
      // إذا كان يبدأ بـ http/https، استخدمه كما هو
      if (!picture.startsWith('http')) {
        // إذا لم يكن full URL، لا نحتاج معالجة (CachedNetworkImage سيتعامل معه)
      }
      // إذا كان فيه تكرار، نصلحه
      if (picture.contains('content/uploads/http')) {
        // استخرج الـ URL الصحيح (بعد uploads/)
        final index = picture.indexOf('https://', picture.indexOf('uploads/'));
        if (index != -1) {
          picture = picture.substring(index);
        }
      }
    }
    
    return EventMember(
      userId: json['user_id'].toString(),
      userName: json['user_name'].toString(),
      firstName: json['user_firstname']?.toString(),
      lastName: json['user_lastname']?.toString(),
      userPicture: picture,
      membershipStatus: json['membership_status']?.toString() ?? 'going',
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'].toString())
          : DateTime.now(),
      isAdmin: json['is_admin'] == true || json['is_admin'] == '1' || json['is_admin'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_firstname': firstName,
      'user_lastname': lastName,
      'user_picture': userPicture,
      'membership_status': membershipStatus,
      'joined_at': joinedAt.toIso8601String(),
      'is_admin': isAdmin,
    };
  }

  String get fullName {
    if (firstName == null && lastName == null) return userName;
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  bool get isGoing => membershipStatus == 'going';
  bool get isInterested => membershipStatus == 'interested';
  bool get isInvited => membershipStatus == 'invited';

  @override
  List<Object?> get props => [
        userId,
        userName,
        firstName,
        lastName,
        userPicture,
        membershipStatus,
        joinedAt,
        isAdmin,
      ];
}
