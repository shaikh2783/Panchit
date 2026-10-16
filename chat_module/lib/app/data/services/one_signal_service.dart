import 'dart:async';
import 'dart:io';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../../../settings.dart';
import '../../core/storage/app_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class OneSignalService {
  OneSignalService(this._apiClient, this._preferences);

  final ChatModuleApiClient _apiClient;
  final ChatAppPreferences _preferences;

  bool _initialized = false;
  bool _observersAttached = false;
  int? _currentUserId;

  bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) {
      return;
    }

    final appId = oneSignalAppId.trim();
    if (appId.isEmpty) {
      return;
    }

    if (verboseApiLoggingEnabled || traceLoggingEnabled) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    } else {
      OneSignal.Debug.setLogLevel(OSLogLevel.none);
    }

    await OneSignal.initialize(appId);
    _initialized = true;
    _attachObservers();
  }

  Future<void> syncUserSession({
    required int userId,
    String? authTokenOverride,
    bool requestPermission = false,
  }) async {
    if (userId <= 0) {
      return;
    }

    await initialize();
    if (!_initialized) {
      return;
    }

    _currentUserId = userId;
    await OneSignal.login(userId.toString());

    if (requestPermission) {
      await _requestPermissionIfNeeded();
    }

    await _registerCurrentSubscription(
      userId: userId,
      authTokenOverride: authTokenOverride,
    );
  }

  Future<void> detachCurrentUser({bool deleteRemote = true}) async {
    final userId = _resolveStoredUserId();
    final authToken = _resolveAuthToken();
    final subscriptionId = _resolveCurrentSubscriptionId();

    if (deleteRemote &&
        userId > 0 &&
        authToken != null &&
        authToken.isNotEmpty &&
        subscriptionId.isNotEmpty) {
      try {
        await _apiClient.post(
          ApiEndpoints.userOneSignalDelete,
          authenticated: true,
          authTokenOverride: authToken,
          body: _buildOneSignalPayload(subscriptionId),
        );
      } catch (_) {
        // Keep local logout resilient even if the backend request fails.
      }
    }

    if (_initialized) {
      try {
        await OneSignal.logout();
      } catch (_) {}
    }

    _currentUserId = null;
    await _preferences.clearOneSignalRegisteredSubscription();
  }

  void _attachObservers() {
    if (_observersAttached) {
      return;
    }

    _observersAttached = true;
    OneSignal.User.pushSubscription.addObserver((stateChanges) {
      unawaited(
        _handleSubscriptionChange(stateChanges.current.id?.trim() ?? ''),
      );
    });
  }

  Future<void> _handleSubscriptionChange(String subscriptionId) async {
    if (subscriptionId.isEmpty) {
      return;
    }

    final userId = _resolveStoredUserId();
    if (userId <= 0) {
      return;
    }

    await _registerSubscriptionId(
      userId: userId,
      subscriptionId: subscriptionId,
    );
  }

  Future<void> _registerCurrentSubscription({
    required int userId,
    String? authTokenOverride,
  }) async {
    final subscriptionId = OneSignal.User.pushSubscription.id?.trim() ?? '';
    if (subscriptionId.isEmpty) {
      return;
    }

    await _registerSubscriptionId(
      userId: userId,
      subscriptionId: subscriptionId,
      authTokenOverride: authTokenOverride,
    );
  }

  Future<void> _registerSubscriptionId({
    required int userId,
    required String subscriptionId,
    String? authTokenOverride,
  }) async {
    final normalizedSubscriptionId = subscriptionId.trim();
    if (normalizedSubscriptionId.isEmpty ||
        _isDuplicateRegistration(userId, normalizedSubscriptionId)) {
      return;
    }

    final authToken = _resolveAuthToken(authTokenOverride: authTokenOverride);
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    try {
      await _apiClient.post(
        ApiEndpoints.userOneSignalRegister,
        authenticated: true,
        authTokenOverride: authToken,
        body: _buildOneSignalPayload(normalizedSubscriptionId),
      );
      await _preferences.setOneSignalRegisteredSubscription(
        subscriptionId: normalizedSubscriptionId,
        userId: userId,
      );
    } catch (_) {
      // Ignore transient OneSignal registration failures.
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (_preferences.hasOneSignalPermissionPrompted()) {
      return;
    }

    final canRequest = await OneSignal.Notifications.canRequest();
    await _preferences.setOneSignalPermissionPrompted(true);
    if (!canRequest) {
      return;
    }

    try {
      await OneSignal.Notifications.requestPermission(false);
    } catch (_) {}
  }

  Map<String, dynamic> _buildOneSignalPayload(String subscriptionId) {
    return <String, dynamic>{
      'onesignal_id': subscriptionId,
      'subscription_id': subscriptionId,
      'device_type': _resolveDeviceType(),
    };
  }

  String _resolveDeviceType() {
    if (Platform.isAndroid) {
      return 'A';
    }
    if (Platform.isIOS) {
      return 'I';
    }
    return 'W';
  }

  bool _isDuplicateRegistration(int userId, String subscriptionId) {
    return _preferences.getOneSignalRegisteredUserId() == userId &&
        _preferences.getOneSignalRegisteredSubscriptionId() == subscriptionId;
  }

  int _resolveStoredUserId() {
    return _currentUserId ??
        _preferences.getUserId() ??
        _preferences.getPendingUserId() ??
        _preferences.getOneSignalRegisteredUserId() ??
        0;
  }

  String _resolveCurrentSubscriptionId() {
    return OneSignal.User.pushSubscription.id?.trim() ??
        _preferences.getOneSignalRegisteredSubscriptionId()?.trim() ??
        '';
  }

  String? _resolveAuthToken({String? authTokenOverride}) {
    final override = authTokenOverride?.trim() ?? '';
    if (override.isNotEmpty) {
      return override;
    }

    final authToken = _preferences.getAuthToken()?.trim() ?? '';
    if (authToken.isNotEmpty) {
      return authToken;
    }

    final pendingToken = _preferences.getPendingAuthToken()?.trim() ?? '';
    if (pendingToken.isNotEmpty) {
      return pendingToken;
    }

    return null;
  }
}
