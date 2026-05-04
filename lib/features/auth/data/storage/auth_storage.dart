import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:snginepro/features/auth/domain/models/auth_session.dart';
import 'package:snginepro/features/auth/domain/models/stored_auth_account.dart';

class AuthStorage {
  AuthStorage(this._prefs);

  static const _tokenKey = 'auth.token';
  static const _sessionIdKey = 'auth.sessionId';
  static const _userKey = 'auth.user';
  static const _accountsKey = 'auth.accounts';
  static const _activeAccountIdKey = 'auth.activeAccountId';

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

  Future<void> saveAccount(StoredAuthAccount account, {bool makeActive = true}) async {
    final accounts = await readAccounts();
    final updated = List<StoredAuthAccount>.from(accounts);
    final index = updated.indexWhere((item) => item.accountId == account.accountId);
    if (index == -1) {
      updated.add(account);
    } else {
      updated[index] = account;
    }

    await _persistAccounts(updated);

    if (makeActive) {
      await setActiveAccount(account.accountId);
      await saveSession(account.toSession());
    }
  }

  Future<List<StoredAuthAccount>> readAccounts() async {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return _readLegacyAccountList();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return _readLegacyAccountList();
      }

      final accounts = decoded
          .whereType<Map>()
          .map(
            (entry) => StoredAuthAccount.fromJson(
              entry.map(
                (key, dynamic value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .where((account) => account.accountId.isNotEmpty && account.token.isNotEmpty)
          .toList();

      if (accounts.isEmpty) {
        return _readLegacyAccountList();
      }

      return accounts;
    } catch (_) {
      return _readLegacyAccountList();
    }
  }

  Future<StoredAuthAccount?> readActiveAccount() async {
    final accounts = await readAccounts();
    if (accounts.isEmpty) {
      return null;
    }

    final activeAccountId = _prefs.getString(_activeAccountIdKey);
    if (activeAccountId != null && activeAccountId.isNotEmpty) {
      for (final account in accounts) {
        if (account.accountId == activeAccountId) {
          return account;
        }
      }
    }

    return accounts.first;
  }

  Future<void> setActiveAccount(String accountId) async {
    await _prefs.setString(_activeAccountIdKey, accountId);
  }

  Future<void> removeAccount(String accountId) async {
    final accounts = await readAccounts();
    final updated = accounts.where((account) => account.accountId != accountId).toList();
    await _persistAccounts(updated);

    final activeAccountId = _prefs.getString(_activeAccountIdKey);
    if (activeAccountId == accountId) {
      if (updated.isEmpty) {
        await clearSession();
        await _prefs.remove(_activeAccountIdKey);
      } else {
        final fallback = updated.first;
        await setActiveAccount(fallback.accountId);
        await saveSession(fallback.toSession());
      }
    }
  }

  Future<AuthSession?> readSession() async {
    final activeAccount = await readActiveAccount();
    if (activeAccount != null && activeAccount.token.isNotEmpty) {
      await saveSession(activeAccount.toSession());
      return activeAccount.toSession();
    }

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

  Future<void> clearAllAccounts() async {
    await clearSession();
    await Future.wait([
      _prefs.remove(_accountsKey),
      _prefs.remove(_activeAccountIdKey),
    ]);
  }

  Future<void> _persistAccounts(List<StoredAuthAccount> accounts) async {
    if (accounts.isEmpty) {
      await _prefs.remove(_accountsKey);
      return;
    }

    final payload = jsonEncode(accounts.map((account) => account.toJson()).toList());
    await _prefs.setString(_accountsKey, payload);
  }

  Future<List<StoredAuthAccount>> _readLegacyAccountList() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return const [];
    }

    final sessionId = _prefs.getString(_sessionIdKey);
    final userJson = _prefs.getString(_userKey);
    final user = userJson != null
        ? jsonDecode(userJson) as Map<String, dynamic>
        : null;

    final account = StoredAuthAccount(
      accountId: _buildAccountId(
        userId: _readUserField(user, ['user_id', 'id']),
        username: _readUserField(user, ['user_name', 'username']),
        email: _readUserField(user, ['user_email', 'email']),
        token: token,
      ),
      token: token,
      sessionId: sessionId,
      userId: _readUserField(user, ['user_id', 'id']),
      username: _readUserField(user, ['user_name', 'username']),
      email: _readUserField(user, ['user_email', 'email']),
      displayName: _readUserField(user, [
        'user_fullname',
        'name',
        'display_name',
      ]),
      avatarUrl: _readUserField(user, ['user_picture', 'avatar', 'picture']),
      user: user,
    );

    await _persistAccounts([account]);
    await setActiveAccount(account.accountId);
    return [account];
  }

  static String _buildAccountId({
    String? userId,
    String? username,
    String? email,
    required String token,
  }) {
    if (userId != null && userId.isNotEmpty) {
      return 'user:$userId';
    }
    if (username != null && username.isNotEmpty) {
      return 'username:$username';
    }
    if (email != null && email.isNotEmpty) {
      return 'email:$email';
    }
    final suffix = token.length > 12 ? token.substring(token.length - 12) : token;
    return 'token:$suffix';
  }

  static String? _readUserField(Map<String, dynamic>? user, List<String> keys) {
    if (user == null) return null;
    for (final key in keys) {
      final value = user[key];
      if (value == null) {
        continue;
      }
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) {
        return stringValue;
      }
    }
    return null;
  }
}
