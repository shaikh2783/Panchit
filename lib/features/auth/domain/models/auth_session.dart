import 'dart:convert';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
class AuthSession {
  AuthSession({
    required this.token,
    this.sessionId,
    Map<String, dynamic>? user,
  }) : user = user != null ? Map.unmodifiable(user) : null;
  final String token;
  final String? sessionId;
  final Map<String, dynamic>? user;
  factory AuthSession.fromResponse(AuthResponse response) {
    final token = response.authToken;
    if (token == null || token.isEmpty) {
      throw StateError('Cannot build AuthSession without auth token');
    }
    return AuthSession(
      token: token,
      sessionId: response.sessionId,
      user: response.user,
    );
  }
  Map<String, Object?> toJson() {
    return {
      'token': token,
      'sessionId': sessionId,
      'user': user,
    };
  }
  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      token: json['token'] as String,
      sessionId: json['sessionId'] as String?,
      user: _decodeUser(json['user']),
    );
  }
  static Map<String, dynamic>? _decodeUser(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return jsonDecode(value) as Map<String, dynamic>;
    }
    return null;
  }
}
