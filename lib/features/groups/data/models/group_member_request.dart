/// نموذج طلب انضمام لمجموعة
class GroupMemberRequest {
  final int userId;
  final String username;
  final String firstname;
  final String lastname;
  final String fullname;
  final String picture;
  final bool verified;
  final String requestDate;

  GroupMemberRequest({
    required this.userId,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.fullname,
    required this.picture,
    required this.verified,
    required this.requestDate,
  });

  factory GroupMemberRequest.fromJson(Map<String, dynamic> json) {

    final userId = int.tryParse(json['user_id']?.toString() ?? '0') ?? 0;
    final username =
        json['user_name']?.toString() ?? ''; // تغيير من username إلى user_name
    final firstname =
        json['user_firstname']?.toString() ??
        ''; // تغيير من firstname إلى user_firstname
    final lastname =
        json['user_lastname']?.toString() ??
        ''; // تغيير من lastname إلى user_lastname
    final fullname =
        '${json['user_firstname']?.toString() ?? ''} ${json['user_lastname']?.toString() ?? ''}'
            .trim();


    return GroupMemberRequest(
      userId: userId,
      username: username,
      firstname: firstname,
      lastname: lastname,
      fullname: fullname.isEmpty
          ? username
          : fullname, // استخدام username كبديل إذا كان fullname فارغ
      picture:
          json['user_picture']?.toString() ??
          '', // تغيير من picture إلى user_picture
      verified:
          json['user_verified'] == true ||
          json['user_verified'] == 1 ||
          json['user_verified'] == '1', // تغيير من verified إلى user_verified
      requestDate:
          json['request_date']?.toString() ??
          json['timestamp']?.toString() ??
          '', // محاولة الحصول على التاريخ من أي مصدر متاح
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'fullname': fullname,
      'picture': picture,
      'verified': verified,
      'request_date': requestDate,
    };
  }
}
