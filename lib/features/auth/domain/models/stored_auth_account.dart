import 'dart:collection';

import 'package:snginepro/features/auth/domain/models/auth_session.dart';

class StoredAuthAccount {
  StoredAuthAccount({
    required this.accountId,
    required this.token,
    this.sessionId,
    this.userId,
    this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.provider = 'credentials',
    Map<String, dynamic>? user,
    DateTime? addedAt,
    DateTime? lastUsedAt,
  })  : user = user != null ? UnmodifiableMapView(user) : null,
        addedAt = addedAt ?? DateTime.now(),
        lastUsedAt = lastUsedAt ?? DateTime.now();

  final String accountId;
  final String token;
  final String? sessionId;
  final String? userId;
  final String? username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String provider;
  final Map<String, dynamic>? user;
  final DateTime addedAt;
  final DateTime lastUsedAt;

  AuthSession toSession() {
    return AuthSession(
      token: token,
      sessionId: sessionId,
      user: user,
    );
  }

  StoredAuthAccount copyWith({
    String? accountId,
    String? token,
    Object? sessionId = _sentinel,
    Object? userId = _sentinel,
    Object? username = _sentinel,
    Object? email = _sentinel,
    Object? displayName = _sentinel,
    Object? avatarUrl = _sentinel,
    String? provider,
    Object? user = _sentinel,
    DateTime? addedAt,
    DateTime? lastUsedAt,
  }) {
    return StoredAuthAccount(
      accountId: accountId ?? this.accountId,
      token: token ?? this.token,
      sessionId: identical(sessionId, _sentinel)
          ? this.sessionId
          : sessionId as String?,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
      username: identical(username, _sentinel)
          ? this.username
          : username as String?,
      email: identical(email, _sentinel) ? this.email : email as String?,
      displayName: identical(displayName, _sentinel)
          ? this.displayName
          : displayName as String?,
      avatarUrl: identical(avatarUrl, _sentinel)
          ? this.avatarUrl
          : avatarUrl as String?,
      provider: provider ?? this.provider,
      user: identical(user, _sentinel) ? this.user : user as Map<String, dynamic>?,
      addedAt: addedAt ?? this.addedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'accountId': accountId,
      'token': token,
      'sessionId': sessionId,
      'userId': userId,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'provider': provider,
      'user': user,
      'addedAt': addedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  factory StoredAuthAccount.fromJson(Map<String, dynamic> json) {
    return StoredAuthAccount(
      accountId: _readString(json['accountId']) ?? '',
      token: _readString(json['token']) ?? '',
      sessionId: _readString(json['sessionId']),
      userId: _readString(json['userId']),
      username: _readString(json['username']),
      email: _readString(json['email']),
      displayName: _readString(json['displayName']),
      avatarUrl: _readString(json['avatarUrl']),
      provider: _readString(json['provider']) ?? 'credentials',
      user: _normalizeMap(json['user']),
      addedAt: _parseDateTime(json['addedAt']),
      lastUsedAt: _parseDateTime(json['lastUsedAt']),
    );
  }

  static String? _readString(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
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

  static DateTime _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

const Object _sentinel = Object();
