import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snginepro/features/auth/domain/models/auth_session.dart';
class AuthStorage {
  AuthStorage(this._prefs);
  static const _tokenKey = 'auth.token';
  static const _sessionIdKey = 'auth.sessionId';
  static const _userKey = 'auth.user';
  final SharedPreferences _prefs;
  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _prefs.setString(_tokenKey, session.token),
      if (session.sessionId != null)
        _prefs.setString(_sessionIdKey, session.sessionId!)
      else
        _prefs.remove(_sessionIdKey),
      if (session.user != null)
        _prefs.setString(_userKey, jsonEncode(session.user))
      else
        _prefs.remove(_userKey),
    ]);
  }
  Future<AuthSession?> readSession() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    final sessionId = _prefs.getString(_sessionIdKey);
    final userJson = _prefs.getString(_userKey);
    final user =
        userJson != null ? jsonDecode(userJson) as Map<String, dynamic> : null;
    return AuthSession(
      token: token,
      sessionId: sessionId,
      user: user,
    );
  }
  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_tokenKey),
      _prefs.remove(_sessionIdKey),
      _prefs.remove(_userKey),
    ]);
  }
}
