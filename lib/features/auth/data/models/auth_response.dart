import 'dart:collection';

class AuthResponse {
  AuthResponse({
    required this.status,
    required this.message,
    required this.authToken,
    required Map<String, dynamic>? data,
    required Map<String, dynamic>? user,
    required Map<String, dynamic> payload,
  })  : data = data != null ? UnmodifiableMapView(data) : null,
        user = user != null ? UnmodifiableMapView(user) : null,
        raw = UnmodifiableMapView(payload);

  final String? status;
  final String? message;
  final String? authToken;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? user;
  final Map<String, dynamic> raw;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final normalizedPayload = Map<String, dynamic>.from(json);
    final normalizedData = _normalizeMap(json['data']);
    final normalizedUser =
        normalizedData != null ? _normalizeMap(normalizedData['user']) : null;

    return AuthResponse(
      status: _string(json['status']),
      message: _extractMessage(json),
      authToken: _extractAuthToken(json),
      data: normalizedData,
      user: normalizedUser,
      payload: normalizedPayload,
    );
  }

  bool get isSuccess => status?.toLowerCase() == 'success';

  String? get userDisplayName {
    final fullName = _string(user?['user_fullname']);
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final firstName = _string(user?['user_firstname']);
    final lastName = _string(user?['user_lastname']);
    final parts = <String>[];
    if (firstName != null && firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName != null && lastName.isNotEmpty) {
      parts.add(lastName);
    }
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    final username = _string(user?['user_name']);
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return null;
  }

  String? get sessionId {
    final sessionFromData = _string(data?['session_id']);
    if (sessionFromData != null && sessionFromData.isNotEmpty) {
      return sessionFromData;
    }
    final activeSession = _string(user?['active_session_id']);
    if (activeSession != null && activeSession.isNotEmpty) {
      return activeSession;
    }
    return null;
  }

  String? get userId {
    final id = data?['user_id'] ?? user?['user_id'];
    return _string(id);
  }

  bool? get needActivation {
    final value = data?['need_activation'];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  String? get activationType {
    return _string(data?['activation_type']);
  }

  static String? _extractMessage(Map<String, dynamic> json) {
    final candidates = [
      json['message'],
      json['status_message'],
      json['statusMessage'],
      json['status_text'],
      json['error'],
      json['detail'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return _extractMessage(data);
    }
    return null;
  }

  static String? _extractAuthToken(Map<String, dynamic> json) {
    final candidates = [
      json['auth_token'],
      json['authToken'],
      json['token'],
      json['access_token'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return _extractAuthToken(data);
    }
    return null;
  }

  static Map<String, dynamic>? _normalizeMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map(
        (key, dynamic entryValue) => MapEntry(key.toString(), entryValue),
      );
    }
    return null;
  }

  static String? _string(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }
}
