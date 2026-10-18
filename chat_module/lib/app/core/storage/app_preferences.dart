import 'package:shared_preferences/shared_preferences.dart';

class ChatAppPreferences {
  ChatAppPreferences._(this._preferences);

  // All keys are prefixed with `chat_` because this module shares a single
  // on-device SharedPreferences instance with the host EximBuzz app, whose
  // own ChatAppPreferences uses these same unprefixed key names for its own
  // (unrelated) session.
  static const String authTokenKey = 'chat_auth_token';
  static const String userIdKey = 'chat_user_id';
  static const String pendingAuthTokenKey = 'chat_pending_auth_token';
  static const String pendingUserIdKey = 'chat_pending_user_id';
  static const String pendingNextStepKey = 'chat_pending_next_step';
  static const String pendingEmailKey = 'chat_pending_email';
  static const String pendingUserNameKey = 'chat_pending_user_name';
  static const String pendingUserPictureKey = 'chat_pending_user_picture';
  static const String timelineBridgeAvailableKey =
      'chat_timeline_bridge_available';
  static const String activeTimelineBridgeKey = 'chat_active_timeline_bridge';
  static const String localeKey = 'chat_app_locale';
  static const String themeModeKey = 'chat_theme_mode';
  // Unprefixed on purpose: this is the host app's own dark/light switch key
  // (see lib/core/theme/theme_controller.dart in the host app). Chat reads
  // and writes it directly so both apps always agree on light vs dark.
  static const String hostDarkModeKey = 'theme_mode';
  static const String oneSignalRegisteredSubscriptionIdKey =
      'chat_onesignal_registered_subscription_id';
  static const String oneSignalRegisteredUserIdKey =
      'chat_onesignal_registered_user_id';
  static const String oneSignalPermissionPromptedKey =
      'chat_onesignal_permission_prompted';
  static const String diagnosticDeviceIdKey = 'chat_diagnostic_device_id';
  static const String fcmRegisteredTokenKey = 'chat_fcm_registered_token';
  static const String fcmRegisteredUserIdKey = 'chat_fcm_registered_user_id';
  static const String fullScreenIntentPermissionPromptedKey =
      'chat_full_screen_intent_permission_prompted';
  static const String batteryOptimizationPromptedKey =
      'chat_battery_optimization_prompted';
  static const String pendingIncomingCallPayloadKey =
      'chat_pending_incoming_call_payload';
  static const String voipPushTokenKey = 'chat_voip_push_token';
  static const String voipRegisteredTokenKey = 'chat_voip_registered_token';
  static const String voipRegisteredUserIdKey =
      'chat_voip_registered_user_id';
  static const String consumedInitialDeepLinkKey =
      'chat_consumed_initial_deep_link';
  static const String consumedInitialDeepLinkAtKey =
      'chat_consumed_initial_deep_link_at';
  static const String _legacyApiBaseUrlKey = 'chat_api_base_url';
  static const String _legacyApiKeyKey = 'chat_api_key';
  static const String _legacyApiSecretKeyKey = 'chat_api_secret_key';

  final SharedPreferences _preferences;

  static Future<ChatAppPreferences> create() async {
    final preferences = await SharedPreferences.getInstance();
    return ChatAppPreferences._(preferences);
  }

  Future<void> reload() {
    return _preferences.reload();
  }

  String? getAuthToken() => _preferences.getString(authTokenKey);

  Future<bool> setAuthToken(String token) {
    return _preferences.setString(authTokenKey, token);
  }

  int? getUserId() => _preferences.getInt(userIdKey);

  Future<bool> setUserId(int userId) {
    return _preferences.setInt(userIdKey, userId);
  }

  Future<bool> setActiveTimelineBridgeSession(bool value) {
    return _preferences.setBool(activeTimelineBridgeKey, value);
  }

  String? getPendingAuthToken() => _preferences.getString(pendingAuthTokenKey);

  int? getPendingUserId() => _preferences.getInt(pendingUserIdKey);

  String? getPendingNextStep() => _preferences.getString(pendingNextStepKey);

  String? getPendingEmail() => _preferences.getString(pendingEmailKey);

  String? getPendingUserName() => _preferences.getString(pendingUserNameKey);

  String? getPendingUserPicture() =>
      _preferences.getString(pendingUserPictureKey);

  bool hasTimelineBridgeSession() =>
      _preferences.getBool(timelineBridgeAvailableKey) ?? false;

  bool isActiveTimelineBridgeSession() =>
      _preferences.getBool(activeTimelineBridgeKey) ?? false;

  String? getLocaleValue() => _preferences.getString(localeKey);

  Future<bool> setLocaleValue(String value) {
    return _preferences.setString(localeKey, value);
  }

  String? getThemeModeValue() => _preferences.getString(themeModeKey);

  Future<bool> setThemeModeValue(String value) {
    return _preferences.setString(themeModeKey, value);
  }

  bool? getHostDarkMode() => _preferences.getBool(hostDarkModeKey);

  Future<bool> setHostDarkMode(bool isDark) {
    return _preferences.setBool(hostDarkModeKey, isDark);
  }

  String? getOneSignalRegisteredSubscriptionId() =>
      _preferences.getString(oneSignalRegisteredSubscriptionIdKey);

  int? getOneSignalRegisteredUserId() =>
      _preferences.getInt(oneSignalRegisteredUserIdKey);

  Future<bool> setOneSignalRegisteredSubscription({
    required String subscriptionId,
    required int userId,
  }) async {
    final storedSubscription = await _preferences.setString(
      oneSignalRegisteredSubscriptionIdKey,
      subscriptionId,
    );
    final storedUserId = await _preferences.setInt(
      oneSignalRegisteredUserIdKey,
      userId,
    );
    return storedSubscription && storedUserId;
  }

  Future<void> clearOneSignalRegisteredSubscription() async {
    await _preferences.remove(oneSignalRegisteredSubscriptionIdKey);
    await _preferences.remove(oneSignalRegisteredUserIdKey);
  }

  bool hasOneSignalPermissionPrompted() =>
      _preferences.getBool(oneSignalPermissionPromptedKey) ?? false;

  Future<bool> setOneSignalPermissionPrompted(bool value) {
    return _preferences.setBool(oneSignalPermissionPromptedKey, value);
  }

  String? getDiagnosticDeviceId() =>
      _preferences.getString(diagnosticDeviceIdKey);

  Future<bool> setDiagnosticDeviceId(String value) {
    return _preferences.setString(diagnosticDeviceIdKey, value);
  }

  String? getFcmRegisteredToken() =>
      _preferences.getString(fcmRegisteredTokenKey);

  int? getFcmRegisteredUserId() => _preferences.getInt(fcmRegisteredUserIdKey);

  Future<bool> setFcmRegisteredToken({
    required String token,
    required int userId,
  }) async {
    final storedToken = await _preferences.setString(
      fcmRegisteredTokenKey,
      token,
    );
    final storedUserId = await _preferences.setInt(
      fcmRegisteredUserIdKey,
      userId,
    );
    return storedToken && storedUserId;
  }

  Future<void> clearFcmRegisteredToken() async {
    await _preferences.remove(fcmRegisteredTokenKey);
    await _preferences.remove(fcmRegisteredUserIdKey);
  }

  bool hasFullScreenIntentPermissionPrompted() =>
      _preferences.getBool(fullScreenIntentPermissionPromptedKey) ?? false;

  Future<bool> setFullScreenIntentPermissionPrompted(bool value) {
    return _preferences.setBool(fullScreenIntentPermissionPromptedKey, value);
  }

  bool hasBatteryOptimizationPrompted() =>
      _preferences.getBool(batteryOptimizationPromptedKey) ?? false;

  Future<bool> setBatteryOptimizationPrompted(bool value) {
    return _preferences.setBool(batteryOptimizationPromptedKey, value);
  }

  String? getPendingIncomingCallPayload() =>
      _preferences.getString(pendingIncomingCallPayloadKey);

  Future<bool> setPendingIncomingCallPayload(String payload) {
    return _preferences.setString(pendingIncomingCallPayloadKey, payload);
  }

  Future<void> clearPendingIncomingCallPayload() async {
    await _preferences.remove(pendingIncomingCallPayloadKey);
  }

  String? getVoipPushToken() => _preferences.getString(voipPushTokenKey);

  Future<bool> setVoipPushToken(String token) {
    return _preferences.setString(voipPushTokenKey, token);
  }

  Future<void> clearVoipPushToken() async {
    await _preferences.remove(voipPushTokenKey);
  }

  String? getVoipRegisteredToken() =>
      _preferences.getString(voipRegisteredTokenKey);

  int? getVoipRegisteredUserId() =>
      _preferences.getInt(voipRegisteredUserIdKey);

  Future<bool> setVoipRegisteredToken({
    required String token,
    required int userId,
  }) async {
    final storedToken = await _preferences.setString(
      voipRegisteredTokenKey,
      token,
    );
    final storedUserId = await _preferences.setInt(
      voipRegisteredUserIdKey,
      userId,
    );
    return storedToken && storedUserId;
  }

  Future<void> clearVoipRegisteredToken() async {
    await _preferences.remove(voipRegisteredTokenKey);
    await _preferences.remove(voipRegisteredUserIdKey);
  }

  Future<void> clearLegacyApiRuntimeCache() async {
    await _preferences.remove(_legacyApiBaseUrlKey);
    await _preferences.remove(_legacyApiKeyKey);
    await _preferences.remove(_legacyApiSecretKeyKey);
  }

  bool hasActiveSession() {
    final token = getAuthToken();
    return token != null && token.trim().isNotEmpty;
  }

  String? getConsumedInitialDeepLink() {
    return _preferences.getString(consumedInitialDeepLinkKey);
  }

  int? getConsumedInitialDeepLinkAt() {
    return _preferences.getInt(consumedInitialDeepLinkAtKey);
  }

  Future<void> setConsumedInitialDeepLink({
    required String link,
    required int consumedAt,
  }) async {
    await _preferences.setString(consumedInitialDeepLinkKey, link);
    await _preferences.setInt(consumedInitialDeepLinkAtKey, consumedAt);
  }

  bool hasPendingSession() {
    final token = getPendingAuthToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> setPendingSession({
    required String token,
    required int userId,
    required String nextStep,
    String? email,
    String? userName,
    String? userPicture,
    bool timelineBridge = false,
  }) async {
    await _preferences.setString(pendingAuthTokenKey, token);
    await _preferences.setInt(pendingUserIdKey, userId);
    await _preferences.setString(pendingNextStepKey, nextStep);
    await _preferences.setBool(timelineBridgeAvailableKey, timelineBridge);
    if (email != null && email.trim().isNotEmpty) {
      await _preferences.setString(pendingEmailKey, email.trim());
    } else {
      await _preferences.remove(pendingEmailKey);
    }
    if (userName != null && userName.trim().isNotEmpty) {
      await _preferences.setString(pendingUserNameKey, userName.trim());
    } else {
      await _preferences.remove(pendingUserNameKey);
    }
    if (userPicture != null && userPicture.trim().isNotEmpty) {
      await _preferences.setString(pendingUserPictureKey, userPicture.trim());
    } else {
      await _preferences.remove(pendingUserPictureKey);
    }
  }

  Future<void> clearPendingSession() async {
    await _preferences.remove(pendingAuthTokenKey);
    await _preferences.remove(pendingUserIdKey);
    await _preferences.remove(pendingNextStepKey);
    await _preferences.remove(pendingEmailKey);
    await _preferences.remove(pendingUserNameKey);
    await _preferences.remove(pendingUserPictureKey);
    await _preferences.remove(timelineBridgeAvailableKey);
  }

  Future<void> promotePendingSession() async {
    final token = getPendingAuthToken();
    final userId = getPendingUserId();
    final isTimelineBridge = hasTimelineBridgeSession();
    if (token != null && token.trim().isNotEmpty) {
      await _preferences.setString(authTokenKey, token);
    }
    if (userId != null && userId > 0) {
      await _preferences.setInt(userIdKey, userId);
    }
    await _preferences.setBool(activeTimelineBridgeKey, isTimelineBridge);
    await clearPendingSession();
  }

  Future<void> clearSession() async {
    await _preferences.remove(authTokenKey);
    await _preferences.remove(userIdKey);
    await _preferences.remove(activeTimelineBridgeKey);
    await clearPendingSession();
  }
}
