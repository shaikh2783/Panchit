class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.picture,
  });

  final int id;
  final String name;
  final String email;
  final String picture;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['user_firstname']?.toString().trim() ?? '';
    final lastName = json['user_lastname']?.toString().trim() ?? '';
    final fullName = json['user_fullname']?.toString().trim() ?? '';

    return AuthUserModel(
      id: _parseInt(json['user_id']),
      name: fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim(),
      email: json['user_email']?.toString().trim() ?? '',
      picture: json['user_picture']?.toString().trim() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
