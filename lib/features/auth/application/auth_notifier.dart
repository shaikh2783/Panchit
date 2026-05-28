import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';

import 'package:snginepro/core/services/onesignal_service.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/data/storage/auth_storage.dart';
import 'package:snginepro/features/auth/domain/auth_repository.dart';
import 'package:snginepro/features/auth/domain/models/auth_session.dart';
import 'package:snginepro/features/auth/domain/models/stored_auth_account.dart';
import 'package:snginepro/main.dart' show configCfgP;

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._repository, this._storage, this._apiClient) {
    _oneSignalService = OneSignalService(_apiClient);
  }

  final AuthRepository _repository;
  final AuthStorage _storage;
  final ApiClient _apiClient;
  late final OneSignalService _oneSignalService;

  bool _isLoading = false;
  String? _errorMessage;
  AuthResponse? _lastResponse;
  AuthSession? _session;
  List<StoredAuthAccount> _savedAccounts = const [];
  String? _activeAccountId;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthResponse? get lastResponse => _lastResponse;
  String? get authToken => _session?.token ?? _lastResponse?.authToken;
  Map<String, dynamic>? get currentUser =>
      _session?.user ?? _lastResponse?.user;
  String? get sessionId => _session?.sessionId ?? _lastResponse?.sessionId;
  bool get isAuthenticated => _session != null;
  bool get isInitialized => _isInitialized;
  AuthSession? get session => _session;
  List<StoredAuthAccount> get savedAccounts => List.unmodifiable(_savedAccounts);
  String? get activeAccountId => _activeAccountId;
  StoredAuthAccount? get activeAccount {
    if (_activeAccountId == null) return null;
    for (final account in _savedAccounts) {
      if (account.accountId == _activeAccountId) {
        return account;
      }
    }
    return null;
  }
  bool get hasMultipleAccounts => _savedAccounts.length > 1;

  Future<AuthResponse?> signIn({
    required String identity,
    required String password,
    String deviceType = 'A',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _repository.signIn(
        identity: identity,
        password: password,
        deviceType: deviceType,
      );
      _lastResponse = response;
      final token = response.authToken;
      if (token != null && token.isNotEmpty) {
        await _completeAuth(response, provider: 'credentials');
      } else {}
      return response;
    } on ApiException catch (error) {
      if (error.details != null) {}
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<AuthResponse?> signUp({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    String? gender,
    DateTime? birthdate,
    String deviceType = 'A',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _repository.signUp(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        gender: gender,
        birthdate: birthdate,
        deviceType: deviceType,
      );
      _lastResponse = response;
      final token = response.authToken;
      if (token != null && token.isNotEmpty) {
        await _completeAuth(response, provider: 'credentials');
      } else {}
      return response;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<AuthResponse?> signInWithGoogle({
    required String googleId,
    required String email,
    String? firstName,
    String? lastName,
    String? picture,
    String? username,
    String? idToken,
    String deviceType = 'A',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _repository.signInWithGoogle(
        googleId: googleId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        picture: picture,
        username: username,
        idToken: idToken,
        deviceType: deviceType,
      );
      _lastResponse = response;
      final token = response.authToken;
      if (token != null && token.isNotEmpty) {
        await _completeAuth(response, provider: 'google');
      } else {}
      return response;
    } on ApiException catch (error) {
      if (error.details != null) {}
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<AuthResponse?> signInWithApple({
    required String appleId,
    String? email,
    String? firstName,
    String? lastName,
    String? identityToken,
    String deviceType = 'A',
    String? deviceOsVersion,
    String? deviceName,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _repository.signInWithApple(
        appleId: appleId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        identityToken: identityToken,
        deviceType: deviceType,
        deviceOsVersion: deviceOsVersion,
        deviceName: deviceName,
      );
      _lastResponse = response;
      final token = response.authToken;
      if (token != null && token.isNotEmpty) {
        await _completeAuth(response, provider: 'apple');
      } else {}
      return response;
    } on ApiException catch (error) {
      if (error.details != null) {}
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
    } finally {
      _setLoading(false);
    }
    return null;
  }

  Future<void> restoreSession() async {
    try {
      _savedAccounts = await _storage.readAccounts();
      final activeStoredAccount = await _storage.readActiveAccount();
      if (activeStoredAccount != null) {
        await _activateAccount(activeStoredAccount, notify: false);
      }
    } catch (_) {
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// تحديث بيانات المستخدم الحالية (نقاط، متابعون، متابَعون...) من الخادم
  Future<void> refreshCurrentUser() async {
    if (_session == null && _lastResponse == null) return;

    try {
      final response = await _repository.fetchCurrentUserSummary();
      final data = response['data'];

      Map<String, dynamic>? userPayload;
      if (data is Map<String, dynamic>) {
        if (data['user'] is Map<String, dynamic>) {
          userPayload = Map<String, dynamic>.from(data['user']);
        } else {
          userPayload = Map<String, dynamic>.from(data);
        }
      }

      if (userPayload != null) {
        if (_session != null) {
          _session = AuthSession(
            token: _session!.token,
            sessionId: _session!.sessionId,
            user: userPayload,
          );
          await _persistActiveSession(userPayload: userPayload);
        } else if (_lastResponse != null) {
          _lastResponse = AuthResponse(
            status: _lastResponse!.status,
            message: _lastResponse!.message,
            authToken: _lastResponse!.authToken,
            data: _lastResponse!.data,
            user: userPayload,
            payload: _lastResponse!.raw,
          );
        }
        notifyListeners();
      } else {}
    } on ApiException catch (_) {
    } catch (_) {}
  }

  Future<void> signOut() async {
    await signOutCurrentAccount();
  }

  Future<void> signOutCurrentAccount() async {
    // حذف OneSignal Player ID قبل تسجيل الخروج
    try {
      await _oneSignalService.removeOneSignalPlayerId();
    } catch (_) {}

    final activeId = _activeAccountId;
    if (activeId == null) {
      await _storage.clearSession();
      _apiClient.updateAuthToken(null);
      _session = null;
      _lastResponse = null;
      notifyListeners();
      return;
    }

    await _storage.removeAccount(activeId);
    _savedAccounts = await _storage.readAccounts();

    if (_savedAccounts.isEmpty) {
      await _storage.clearAllAccounts();
      _session = null;
      _lastResponse = null;
      _activeAccountId = null;
      _apiClient.updateAuthToken(null);
      notifyListeners();
      return;
    }

    final fallback = await _storage.readActiveAccount();
    if (fallback != null) {
      await _activateAccount(fallback);
      return;
    }

    _session = null;
    _lastResponse = null;
    _activeAccountId = null;
    _apiClient.updateAuthToken(null);
    notifyListeners();
  }

  Future<void> signOutAllAccounts() async {
    try {
      await _oneSignalService.removeOneSignalPlayerId();
    } catch (_) {}

    await _storage.clearAllAccounts();
    _savedAccounts = const [];
    _session = null;
    _lastResponse = null;
    _activeAccountId = null;
    _apiClient.updateAuthToken(null);
    notifyListeners();
  }

  Future<void> switchAccount(String accountId) async {
    final target = _savedAccounts.cast<StoredAuthAccount?>().firstWhere(
      (account) => account?.accountId == accountId,
      orElse: () => null,
    );
    if (target == null) {
      throw StateError('Account not found');
    }

    await _activateAccount(target);
    try {
      await refreshCurrentUser();
    } catch (_) {}
  }

  Future<void> removeAccount(String accountId) async {
    final isActive = accountId == _activeAccountId;
    if (isActive) {
      await signOutCurrentAccount();
      return;
    }

    await _storage.removeAccount(accountId);
    _savedAccounts = await _storage.readAccounts();
    notifyListeners();
  }

  /// تسجيل OneSignal Player ID للإشعارات
  /// يتم استدعاؤها بعد تسجيل الدخول أو إنشاء الحساب
  Future<bool> registerOneSignalPlayerId(String playerId) async {
    if (playerId.isEmpty) {
      return false;
    }

    try {
      return await _oneSignalService.updateOneSignalPlayerId(playerId);
    } catch (e) {
      return false;
    }
  }

  Future<void> updateGettingStarted({
    String? countryId,
    String? work,
    String? education,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final body = <String, dynamic>{};
      if (countryId != null && countryId.isNotEmpty) {
        body['country'] = countryId;
      }
      if (work != null && work.isNotEmpty) {
        body['work'] = work;
      }
      if (education != null && education.isNotEmpty) {
        body['education'] = education;
      }

      await _apiClient.post(
        configCfgP('auth_getting_started_update'),
        body: body,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (error) {
      _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> finishGettingStarted() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _apiClient.post(
        configCfgP('auth_getting_started_finish'),
        body: {},
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (error) {
      _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// تسجيل OneSignal Player ID في الخلفية (لا ننتظر النتيجة)
  void _registerOneSignalInBackground() {
    Future.microtask(() async {
      try {
        final result = await _oneSignalService.registerCurrentPlayerId();
        if (result) {
        } else {}
      } catch (_) {}
    });
  }

  Future<void> _completeAuth(
    AuthResponse response, {
    required String provider,
  }) async {
    final session = AuthSession.fromResponse(response);
    final account = _buildStoredAccount(
      session: session,
      response: response,
      provider: provider,
    );
    await _storage.saveAccount(account, makeActive: true);
    _savedAccounts = await _storage.readAccounts();
    await _activateAccount(account, notify: false);

    // Register push mapping after activating the selected account token.
    _registerOneSignalInBackground();
    notifyListeners();
  }

  Future<void> _activateAccount(
    StoredAuthAccount account, {
    bool notify = true,
  }) async {
    _activeAccountId = account.accountId;
    _session = account.toSession();
    _apiClient.updateAuthToken(account.token);
    await _storage.setActiveAccount(account.accountId);
    await _storage.saveSession(_session!);
    _savedAccounts = await _storage.readAccounts();

    if (notify) {
      notifyListeners();
    }

    _registerOneSignalInBackground();
  }

  Future<void> _persistActiveSession({
    required Map<String, dynamic> userPayload,
  }) async {
    if (_session == null || _activeAccountId == null) {
      return;
    }

    final updatedAccount = _buildStoredAccount(
      session: _session!,
      response: _lastResponse,
      provider: activeAccount?.provider ?? 'credentials',
      userOverride: userPayload,
      accountIdOverride: _activeAccountId,
    );
    await _storage.saveAccount(updatedAccount, makeActive: true);
    _savedAccounts = await _storage.readAccounts();
  }

  StoredAuthAccount _buildStoredAccount({
    required AuthSession session,
    AuthResponse? response,
    required String provider,
    Map<String, dynamic>? userOverride,
    String? accountIdOverride,
  }) {
    final user = userOverride ?? session.user ?? response?.user;
    final userId = _readUserValue(user, const ['user_id', 'id']);
    final username = _readUserValue(user, const ['user_name', 'username']);
    final email = _readUserValue(user, const ['user_email', 'email']);
    final displayName = _readUserValue(user, const [
      'user_fullname',
      'name',
      'display_name',
    ]);
    final avatarUrl = _readUserValue(user, const [
      'user_picture',
      'avatar',
      'picture',
    ]);

    return StoredAuthAccount(
      accountId: accountIdOverride ?? _buildAccountId(
        userId: userId,
        username: username,
        email: email,
        token: session.token,
      ),
      token: session.token,
      sessionId: session.sessionId,
      userId: userId,
      username: username,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      provider: provider,
      user: user,
      lastUsedAt: DateTime.now(),
    );
  }

  String _buildAccountId({
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

  String? _readUserValue(Map<String, dynamic>? user, List<String> keys) {
    if (user == null) return null;
    for (final key in keys) {
      final value = user[key];
      if (value == null) {
        continue;
      }
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }
}
