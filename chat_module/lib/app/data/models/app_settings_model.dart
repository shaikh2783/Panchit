import '../../../settings.dart';

/// Runtime behavior and the versioned visual palette returned by the server.
class AppSettingsModel {
  const AppSettingsModel({
    required this.debug,
    required this.callLoggingEnabled,
    required this.appName,
    required this.appLogo,
    required this.chatPollingEnabled,
    required this.chatPollingIntervalSeconds,
    required this.incomingCallPollingEnabled,
    required this.incomingCallPollingIntervalSeconds,
    required this.agoraHeartbeatEnabled,
    required this.agoraHeartbeatIntervalSeconds,
    required this.agoraEnabled,
    required this.callsEnabled,
    required this.audioCallsEnabled,
    required this.videoCallsEnabled,
    required this.callProvider,
    required this.agoraAppId,
    required this.agoraToken,
    required this.agoraChannelPrefix,
    required this.oneSignalAppId,
    required this.timelineUrlScheme,
    required this.timelineDeepLinkHost,
    required this.timelinePackage,
    required this.timelineAndroidStoreUrl,
    required this.timelineIosStoreUrl,
    required this.themeColors,
    required this.messengerLicenseActive,
    required this.messengerLicenseStatus,
    required this.messengerLicenseMessage,
  });

  final bool debug;
  final bool callLoggingEnabled;
  final String appName;
  final String appLogo;
  final bool chatPollingEnabled;
  final int chatPollingIntervalSeconds;
  final bool incomingCallPollingEnabled;
  final int incomingCallPollingIntervalSeconds;
  final bool agoraHeartbeatEnabled;
  final int agoraHeartbeatIntervalSeconds;
  final bool agoraEnabled;
  final bool callsEnabled;
  final bool audioCallsEnabled;
  final bool videoCallsEnabled;
  final String callProvider;
  final String agoraAppId;
  final String agoraToken;
  final String agoraChannelPrefix;
  final String oneSignalAppId;
  final String timelineUrlScheme;
  final String timelineDeepLinkHost;
  final String timelinePackage;
  final String timelineAndroidStoreUrl;
  final String timelineIosStoreUrl;
  final RuntimeThemeColors themeColors;
  final bool messengerLicenseActive;
  final String messengerLicenseStatus;
  final String messengerLicenseMessage;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final settings = (data['settings'] as Map<String, dynamic>?) ?? const {};
    final license = _resolveLicenseData(data, settings);
    final licenseActive = _parseBool(license['active'] ?? license['ok'], true);
    final licenseStatus = _parseString(license['status'], 'active');
    final licenseMessage = _parseString(
      license['developer_message'] ?? license['message'],
      '',
    );

    return AppSettingsModel(
      debug: _parseBool(settings['debug'], defaultDebug),
      callLoggingEnabled: _parseBool(
        settings['callLoggingEnabled'] ?? settings['call_logging_enabled'],
        defaultCallLoggingEnabled,
      ),
      appName: _parseString(
        settings['appName'] ?? settings['app_name'],
        defaultAppName,
      ),
      appLogo: _parseString(
        settings['appLogo'] ?? settings['app_logo'],
        defaultAppLogo,
      ),
      chatPollingEnabled: _parseBool(
        settings['chatPollingEnabled'],
        defaultChatPollingEnabled,
      ),
      chatPollingIntervalSeconds: _parseInt(
        settings['chatPollingIntervalSeconds'],
        defaultChatPollingIntervalSeconds,
      ),
      incomingCallPollingEnabled: _parseBool(
        settings['incomingCallPollingEnabled'],
        defaultIncomingCallPollingEnabled,
      ),
      incomingCallPollingIntervalSeconds: _parseInt(
        settings['incomingCallPollingIntervalSeconds'],
        defaultIncomingCallPollingIntervalSeconds,
      ),
      agoraHeartbeatEnabled: _parseBool(
        settings['agoraHeartbeatEnabled'],
        defaultAgoraHeartbeatEnabled,
      ),
      agoraHeartbeatIntervalSeconds: _parseInt(
        settings['agoraHeartbeatIntervalSeconds'],
        defaultAgoraHeartbeatIntervalSeconds,
      ),
      agoraEnabled: _parseBool(settings['agoraEnabled'], defaultAgoraEnabled),
      callsEnabled: _parseBool(
        settings['calls_enabled'] ?? settings['callsEnabled'],
        defaultCallsEnabled,
      ),
      audioCallsEnabled: _parseBool(
        settings['audio_calls_enabled'] ?? settings['audioCallsEnabled'],
        defaultAudioCallsEnabled,
      ),
      videoCallsEnabled: _parseBool(
        settings['video_calls_enabled'] ?? settings['videoCallsEnabled'],
        defaultVideoCallsEnabled,
      ),
      callProvider: _parseCallProvider(
        settings['callProvider'] ?? settings['call_provider'],
      ),
      agoraAppId: _parseString(settings['agoraAppId'], defaultAgoraAppId),
      agoraToken: _parseString(settings['agoraToken'], defaultAgoraToken),
      agoraChannelPrefix: _parseString(
        settings['agoraChannelPrefix'],
        defaultAgoraChannelPrefix,
      ),
      oneSignalAppId: _parseString(
        settings['oneSignalAppId'] ??
            settings['onesignalAppId'] ??
            settings['onesignal_app_id'] ??
            settings['one_signal_app_id'],
        defaultOneSignalAppId,
      ),
      timelineUrlScheme: _parseString(
        settings['timelineUrlScheme'] ?? settings['timeline_url_scheme'],
        defaultTimelineUrlScheme,
      ),
      timelineDeepLinkHost: _parseString(
        settings['timelineDeepLinkHost'] ??
            settings['timeline_deep_link_host'] ??
            settings['timelineDomain'],
        defaultTimelineDeepLinkHost,
      ),
      timelinePackage: _parseString(
        settings['timelinePackage'] ?? settings['timeline_package'],
        defaultTimelinePackage,
      ),
      timelineAndroidStoreUrl: _parseString(
        settings['timelineAndroidStoreUrl'] ??
            settings['timeline_android_store_url'],
        defaultTimelineAndroidStoreUrl,
      ),
      timelineIosStoreUrl: _parseString(
        settings['timelineIosStoreUrl'] ?? settings['timeline_ios_store_url'],
        defaultTimelineIosStoreUrl,
      ),
      themeColors: RuntimeThemeColors.fromJson(
        settings['colors'] is Map
            ? Map<String, dynamic>.from(settings['colors'] as Map)
            : const {},
      ),
      messengerLicenseActive: licenseActive,
      messengerLicenseStatus: licenseStatus,
      messengerLicenseMessage: licenseMessage,
    );
  }

  void applyToRuntime() {
    AppRuntimeSettings.debug = debug;
    AppRuntimeSettings.callLoggingEnabled = callLoggingEnabled;
    AppRuntimeSettings.appName = appName;
    AppRuntimeSettings.appLogo = appLogo;
    AppRuntimeSettings.chatPollingEnabled = chatPollingEnabled;
    AppRuntimeSettings.chatPollingIntervalSeconds = chatPollingIntervalSeconds;
    AppRuntimeSettings.incomingCallPollingEnabled = incomingCallPollingEnabled;
    AppRuntimeSettings.incomingCallPollingIntervalSeconds =
        incomingCallPollingIntervalSeconds;
    AppRuntimeSettings.agoraHeartbeatEnabled = agoraHeartbeatEnabled;
    AppRuntimeSettings.agoraHeartbeatIntervalSeconds =
        agoraHeartbeatIntervalSeconds;
    AppRuntimeSettings.agoraEnabled = agoraEnabled;
    AppRuntimeSettings.callsEnabled = callsEnabled;
    AppRuntimeSettings.audioCallsEnabled = audioCallsEnabled;
    AppRuntimeSettings.videoCallsEnabled = videoCallsEnabled;
    AppRuntimeSettings.callProvider = callProvider;
    AppRuntimeSettings.agoraAppId = agoraAppId;
    AppRuntimeSettings.agoraToken = agoraToken;
    AppRuntimeSettings.agoraChannelPrefix = agoraChannelPrefix;
    AppRuntimeSettings.oneSignalAppId = oneSignalAppId;
    AppRuntimeSettings.timelineUrlScheme = timelineUrlScheme;
    AppRuntimeSettings.timelineDeepLinkHost = timelineDeepLinkHost;
    AppRuntimeSettings.timelinePackage = timelinePackage;
    AppRuntimeSettings.timelineAndroidStoreUrl = timelineAndroidStoreUrl;
    AppRuntimeSettings.timelineIosStoreUrl = timelineIosStoreUrl;
    AppRuntimeSettings.themeColors = themeColors;
    final normalizedStatus = messengerLicenseStatus.trim().toLowerCase();
    final isHardBlocked =
        normalizedStatus == 'domain_mismatch' ||
        normalizedStatus == 'wrong_product' ||
        normalizedStatus == 'not_installed';
    AppRuntimeSettings.setMessengerLicenseState(
      active: messengerLicenseActive || !isHardBlocked,
      status: normalizedStatus.isEmpty ? 'active' : normalizedStatus,
      message: isHardBlocked ? messengerLicenseMessage : '',
    );
  }

  static Map<String, dynamic> _resolveLicenseData(
    Map<String, dynamic> data,
    Map<String, dynamic> settings,
  ) {
    final nestedLicense = settings['license'];
    if (nestedLicense is Map<String, dynamic>) {
      return nestedLicense;
    }

    final rootLicense = data['license'];
    if (rootLicense is Map<String, dynamic>) {
      return rootLicense;
    }

    return const <String, dynamic>{};
  }

  static bool _parseBool(dynamic value, bool fallback) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') {
      return true;
    }
    if (normalized == '0' || normalized == 'false') {
      return false;
    }
    return fallback;
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _parseString(dynamic value, String fallback) {
    final parsed = value?.toString().trim() ?? '';
    return parsed.isEmpty ? fallback : parsed;
  }

  static String _parseCallProvider(dynamic value) {
    final parsed = value?.toString().trim().toLowerCase() ?? '';
    return parsed == 'webrtc' ? 'webrtc' : defaultCallProvider;
  }
}
