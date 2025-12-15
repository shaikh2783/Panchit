import 'package:flutter/foundation.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/core/services/onesignal_service.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';
import 'package:snginepro/features/auth/data/storage/auth_storage.dart';
import 'package:snginepro/features/auth/domain/auth_repository.dart';
import 'package:snginepro/features/auth/domain/models/auth_session.dart';
import 'package:snginepro/main.dart' show configCfgP;
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(
    this._repository,
    this._storage,
    this._apiClient,
  ) {
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
  bool _isInitialized = false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthResponse? get lastResponse => _lastResponse;
  String? get authToken => _session?.token ?? _lastResponse?.authToken;
  Map<String, dynamic>? get currentUser => _session?.user ?? _lastResponse?.user;
  String? get sessionId => _session?.sessionId ?? _lastResponse?.sessionId;
  bool get isAuthenticated => _session != null;
  bool get isInitialized => _isInitialized;
  AuthSession? get session => _session;
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
        final session = AuthSession.fromResponse(response);
        await _persistSession(session);
        // تسجيل OneSignal Player ID بعد تسجيل الدخول الناجح
        _registerOneSignalInBackground();
      } else {
      }
      return response;
    } on ApiException catch (error) {
      
      if (error.details != null) {
      }
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
        final session = AuthSession.fromResponse(response);
        await _persistSession(session);
        // تسجيل OneSignal Player ID بعد إنشاء الحساب الناجح
        _registerOneSignalInBackground();
      } else {
      }
      return response;
    } on ApiException catch (error) {
      
      if (error.details != null) {
      }
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
      final storedSession = await _storage.readSession();
      if (storedSession != null) {
        _session = storedSession;
        _apiClient.updateAuthToken(storedSession.token);
        
        // بعد استرجاع الجلسة بنجاح، سجّل OneSignal Player ID في الخلفية
        _registerOneSignalInBackground();
      }
    } catch (error) {
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
  Future<void> signOut() async {
    // حذف OneSignal Player ID قبل تسجيل الخروج
    try {
      await _oneSignalService.removeOneSignalPlayerId();
    } catch (e) {
    }
    await _storage.clearSession();
    _session = null;
    _lastResponse = null;
    _apiClient.updateAuthToken(null);
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
      if (countryId != null && countryId.isNotEmpty) body['country'] = countryId;
      if (work != null && work.isNotEmpty) body['work'] = work;
      if (education != null && education.isNotEmpty) body['education'] = education;
      await _apiClient.post(configCfgP('auth_getting_started_update'), body: body);
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
      await _apiClient.post(configCfgP('auth_getting_started_finish'), body: {});
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
        } else {
        }
      } catch (e) {
      }
    });
  }
  Future<void> _persistSession(AuthSession session) async {
    _session = session;
    _apiClient.updateAuthToken(session.token);
    await _storage.saveSession(session);
    notifyListeners();
  }
}
