import 'package:flutter/material.dart';

const bool defaultDebug = false;
const bool defaultVerboseApiLoggingEnabled = false;
const bool defaultTraceLoggingEnabled = false;
const bool defaultCallLoggingEnabled = true;
const bool defaultGroupsChatLoggingEnabled = false;
const bool defaultGettingStartedFlowEnabled = false;

const bool defaultChatPollingEnabled = false;
const int defaultChatPollingIntervalSeconds = 20;

const bool defaultIncomingCallPollingEnabled = true;
const int defaultIncomingCallPollingIntervalSeconds = 15;
const int defaultIncomingCallDecisionTimeoutSeconds = 60;

const bool defaultAgoraHeartbeatEnabled = true;
const int defaultAgoraHeartbeatIntervalSeconds = 8;

const bool defaultAgoraEnabled = true;
const bool defaultCallsEnabled = true;
const bool defaultAudioCallsEnabled = true;
const bool defaultVideoCallsEnabled = true;
const String defaultCallProvider = 'agora';
const String defaultAgoraAppId = '6a1fcb8a44454844a9b46b271d637e7f';
const String defaultAgoraToken = '';
const String defaultAgoraChannelPrefix = 'messenger_call_';
const String defaultOneSignalAppId = '';
const String defaultTimelineUrlScheme = 'sngine';
const String defaultTimelineDeepLinkHost = 'ukraina.co';
const String defaultTimelinePackage = 'api-addons';
const String defaultTimelineAndroidStoreUrl = '';
const String defaultTimelineIosStoreUrl = '';
const String defaultAppName = 'Messenger';
const String defaultAppLogo = '';

class RuntimeThemeColors {
  const RuntimeThemeColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryPressed,
    required this.primarySoft,
    required this.gradientStart,
    required this.gradientEnd,
    required this.lightCanvas,
    required this.lightGroupedCanvas,
    required this.lightSurface,
    required this.lightSoftSurface,
    required this.lightField,
    required this.lightDivider,
    required this.lightText,
    required this.lightMuted,
    required this.lightSubtle,
    required this.darkCanvas,
    required this.darkGroupedCanvas,
    required this.darkSurface,
    required this.darkSoftSurface,
    required this.darkField,
    required this.darkDivider,
    required this.darkText,
    required this.darkMuted,
    required this.darkSubtle,
    required this.darkPrimarySoft,
    required this.online,
    required this.destructive,
    required this.warning,
  });

  static const defaults = RuntimeThemeColors(
    primary: Color(0xFF5B50F6),
    primaryDark: Color(0xFF4B40E8),
    primaryPressed: Color(0xFF493DE3),
    primarySoft: Color(0xFFF0EEFF),
    gradientStart: Color(0xFF675CF8),
    gradientEnd: Color(0xFF5145ED),
    lightCanvas: Color(0xFFFFFFFF),
    lightGroupedCanvas: Color(0xFFF7F7FA),
    lightSurface: Color(0xFFFFFFFF),
    lightSoftSurface: Color(0xFFF3F3F7),
    lightField: Color(0xFFF4F4F7),
    lightDivider: Color(0xFFE8E8EF),
    lightText: Color(0xFF15172B),
    lightMuted: Color(0xFF6F7385),
    lightSubtle: Color(0xFF9699A8),
    darkCanvas: Color(0xFF101116),
    darkGroupedCanvas: Color(0xFF0B0C10),
    darkSurface: Color(0xFF191A21),
    darkSoftSurface: Color(0xFF23242D),
    darkField: Color(0xFF23242D),
    darkDivider: Color(0xFF2C2E38),
    darkText: Color(0xFFF7F7FA),
    darkMuted: Color(0xFFA7A9B4),
    darkSubtle: Color(0xFF777A87),
    darkPrimarySoft: Color(0xFF2A2750),
    online: Color(0xFF20C66A),
    destructive: Color(0xFFE5484D),
    warning: Color(0xFFF59E0B),
  );

  factory RuntimeThemeColors.fromJson(Map<String, dynamic> json) {
    final brand = _map(json['brand']);
    final light = _map(json['light']);
    final dark = _map(json['dark']);
    final status = _map(json['status']);
    const fallback = defaults;

    return RuntimeThemeColors(
      primary: _color(brand['primary'], fallback.primary),
      primaryDark: _color(brand['primaryDark'], fallback.primaryDark),
      primaryPressed: _color(brand['primaryPressed'], fallback.primaryPressed),
      primarySoft: _color(brand['primarySoft'], fallback.primarySoft),
      gradientStart: _color(brand['gradientStart'], fallback.gradientStart),
      gradientEnd: _color(brand['gradientEnd'], fallback.gradientEnd),
      lightCanvas: _color(light['canvas'], fallback.lightCanvas),
      lightGroupedCanvas: _color(
        light['groupedCanvas'],
        fallback.lightGroupedCanvas,
      ),
      lightSurface: _color(light['surface'], fallback.lightSurface),
      lightSoftSurface: _color(light['softSurface'], fallback.lightSoftSurface),
      lightField: _color(light['field'], fallback.lightField),
      lightDivider: _color(light['divider'], fallback.lightDivider),
      lightText: _color(light['text'], fallback.lightText),
      lightMuted: _color(light['muted'], fallback.lightMuted),
      lightSubtle: _color(light['subtle'], fallback.lightSubtle),
      darkCanvas: _color(dark['canvas'], fallback.darkCanvas),
      darkGroupedCanvas: _color(
        dark['groupedCanvas'],
        fallback.darkGroupedCanvas,
      ),
      darkSurface: _color(dark['surface'], fallback.darkSurface),
      darkSoftSurface: _color(dark['softSurface'], fallback.darkSoftSurface),
      darkField: _color(dark['field'], fallback.darkField),
      darkDivider: _color(dark['divider'], fallback.darkDivider),
      darkText: _color(dark['text'], fallback.darkText),
      darkMuted: _color(dark['muted'], fallback.darkMuted),
      darkSubtle: _color(dark['subtle'], fallback.darkSubtle),
      darkPrimarySoft: _color(dark['primarySoft'], fallback.darkPrimarySoft),
      online: _color(status['online'], fallback.online),
      destructive: _color(status['destructive'], fallback.destructive),
      warning: _color(status['warning'], fallback.warning),
    );
  }

  final Color primary;
  final Color primaryDark;
  final Color primaryPressed;
  final Color primarySoft;
  final Color gradientStart;
  final Color gradientEnd;
  final Color lightCanvas;
  final Color lightGroupedCanvas;
  final Color lightSurface;
  final Color lightSoftSurface;
  final Color lightField;
  final Color lightDivider;
  final Color lightText;
  final Color lightMuted;
  final Color lightSubtle;
  final Color darkCanvas;
  final Color darkGroupedCanvas;
  final Color darkSurface;
  final Color darkSoftSurface;
  final Color darkField;
  final Color darkDivider;
  final Color darkText;
  final Color darkMuted;
  final Color darkSubtle;
  final Color darkPrimarySoft;
  final Color online;
  final Color destructive;
  final Color warning;

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  static Color _color(dynamic value, Color fallback) {
    final raw = value?.toString().trim() ?? '';
    final hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length != 6 && hex.length != 8) return fallback;

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
  }
}

class AppRuntimeSettings {
  AppRuntimeSettings._();

  static bool debug = defaultDebug;
  static bool verboseApiLoggingEnabled = defaultVerboseApiLoggingEnabled;
  static bool traceLoggingEnabled = defaultTraceLoggingEnabled;
  static bool callLoggingEnabled = defaultCallLoggingEnabled;
  static bool groupsChatLoggingEnabled = defaultGroupsChatLoggingEnabled;
  static bool gettingStartedFlowEnabled = defaultGettingStartedFlowEnabled;
  static bool chatPollingEnabled = defaultChatPollingEnabled;
  static int chatPollingIntervalSeconds = defaultChatPollingIntervalSeconds;
  static bool incomingCallPollingEnabled = defaultIncomingCallPollingEnabled;
  static int incomingCallPollingIntervalSeconds =
      defaultIncomingCallPollingIntervalSeconds;
  static int incomingCallDecisionTimeoutSeconds =
      defaultIncomingCallDecisionTimeoutSeconds;
  static bool agoraHeartbeatEnabled = defaultAgoraHeartbeatEnabled;
  static int agoraHeartbeatIntervalSeconds =
      defaultAgoraHeartbeatIntervalSeconds;
  static bool agoraEnabled = defaultAgoraEnabled;
  static bool callsEnabled = defaultCallsEnabled;
  static bool audioCallsEnabled = defaultAudioCallsEnabled;
  static bool videoCallsEnabled = defaultVideoCallsEnabled;
  static String callProvider = defaultCallProvider;
  static String agoraAppId = defaultAgoraAppId;
  static String agoraToken = defaultAgoraToken;
  static String agoraChannelPrefix = defaultAgoraChannelPrefix;
  static String oneSignalAppId = defaultOneSignalAppId;
  static String timelineUrlScheme = defaultTimelineUrlScheme;
  static String timelineDeepLinkHost = defaultTimelineDeepLinkHost;
  static String timelinePackage = defaultTimelinePackage;
  static String timelineAndroidStoreUrl = defaultTimelineAndroidStoreUrl;
  static String timelineIosStoreUrl = defaultTimelineIosStoreUrl;
  static String appName = defaultAppName;
  static String appLogo = defaultAppLogo;
  static RuntimeThemeColors themeColors = RuntimeThemeColors.defaults;

  static bool messengerLicenseActive = true;
  static String messengerLicenseStatus = 'active';
  static String messengerLicenseMessage = '';

  static void resetToDefaults() {
    debug = defaultDebug;
    verboseApiLoggingEnabled = defaultVerboseApiLoggingEnabled;
    traceLoggingEnabled = defaultTraceLoggingEnabled;
    callLoggingEnabled = defaultCallLoggingEnabled;
    groupsChatLoggingEnabled = defaultGroupsChatLoggingEnabled;
    gettingStartedFlowEnabled = defaultGettingStartedFlowEnabled;
    chatPollingEnabled = defaultChatPollingEnabled;
    chatPollingIntervalSeconds = defaultChatPollingIntervalSeconds;
    incomingCallPollingEnabled = defaultIncomingCallPollingEnabled;
    incomingCallPollingIntervalSeconds =
        defaultIncomingCallPollingIntervalSeconds;
    incomingCallDecisionTimeoutSeconds =
        defaultIncomingCallDecisionTimeoutSeconds;
    agoraHeartbeatEnabled = defaultAgoraHeartbeatEnabled;
    agoraHeartbeatIntervalSeconds = defaultAgoraHeartbeatIntervalSeconds;
    agoraEnabled = defaultAgoraEnabled;
    callsEnabled = defaultCallsEnabled;
    audioCallsEnabled = defaultAudioCallsEnabled;
    videoCallsEnabled = defaultVideoCallsEnabled;
    callProvider = defaultCallProvider;
    agoraAppId = defaultAgoraAppId;
    agoraToken = defaultAgoraToken;
    agoraChannelPrefix = defaultAgoraChannelPrefix;
    oneSignalAppId = defaultOneSignalAppId;
    timelineUrlScheme = defaultTimelineUrlScheme;
    timelineDeepLinkHost = defaultTimelineDeepLinkHost;
    timelinePackage = defaultTimelinePackage;
    timelineAndroidStoreUrl = defaultTimelineAndroidStoreUrl;
    timelineIosStoreUrl = defaultTimelineIosStoreUrl;
    appName = defaultAppName;
    appLogo = defaultAppLogo;
    themeColors = RuntimeThemeColors.defaults;

    messengerLicenseActive = true;
    messengerLicenseStatus = 'active';
    messengerLicenseMessage = '';
  }

  static bool get hasInactiveMessengerLicense => false;

  static void setMessengerLicenseInactive(String message) {
    messengerLicenseActive = true;
    messengerLicenseStatus = 'active';
    messengerLicenseMessage = message.trim();
  }

  static void setMessengerLicenseState({
    required bool active,
    required String status,
    required String message,
  }) {
    messengerLicenseActive = true;
    messengerLicenseStatus = 'active';
    messengerLicenseMessage = message.trim();
  }

  static String resolveRuntimeApiMessage(String fallback) {
    if (hasInactiveMessengerLicense) {
      return messengerLicenseMessage;
    }
    return fallback.trim();
  }
}

bool get debug => AppRuntimeSettings.debug;
bool get verboseApiLoggingEnabled =>
    AppRuntimeSettings.verboseApiLoggingEnabled;
bool get traceLoggingEnabled => AppRuntimeSettings.traceLoggingEnabled;
bool get callLoggingEnabled => AppRuntimeSettings.callLoggingEnabled;
bool get groupsChatLoggingEnabled =>
    AppRuntimeSettings.groupsChatLoggingEnabled;
bool get gettingStartedFlowEnabled =>
    AppRuntimeSettings.gettingStartedFlowEnabled;

bool get chatPollingEnabled => AppRuntimeSettings.chatPollingEnabled;
int get chatPollingIntervalSeconds =>
    AppRuntimeSettings.chatPollingIntervalSeconds;
Duration get chatPollingInterval =>
    Duration(seconds: AppRuntimeSettings.chatPollingIntervalSeconds);

bool get incomingCallPollingEnabled =>
    AppRuntimeSettings.incomingCallPollingEnabled;
int get incomingCallPollingIntervalSeconds =>
    AppRuntimeSettings.incomingCallPollingIntervalSeconds;
Duration get incomingCallPollingInterval =>
    Duration(seconds: AppRuntimeSettings.incomingCallPollingIntervalSeconds);
int get incomingCallDecisionTimeoutSeconds =>
    AppRuntimeSettings.incomingCallDecisionTimeoutSeconds;
Duration get incomingCallDecisionTimeout =>
    Duration(seconds: AppRuntimeSettings.incomingCallDecisionTimeoutSeconds);

bool get agoraHeartbeatEnabled => AppRuntimeSettings.agoraHeartbeatEnabled;
int get agoraHeartbeatIntervalSeconds =>
    AppRuntimeSettings.agoraHeartbeatIntervalSeconds;
Duration get agoraHeartbeatInterval =>
    Duration(seconds: AppRuntimeSettings.agoraHeartbeatIntervalSeconds);

bool get agoraEnabled => AppRuntimeSettings.agoraEnabled;
bool get callsEnabled => AppRuntimeSettings.callsEnabled;
bool get audioCallsEnabled => AppRuntimeSettings.audioCallsEnabled;
bool get videoCallsEnabled => AppRuntimeSettings.videoCallsEnabled;
String get callProvider => AppRuntimeSettings.callProvider.trim().toLowerCase();
bool get isAgoraCallProvider => callProvider != 'webrtc';
bool get isWebRtcCallProvider => callProvider == 'webrtc';
String get agoraAppId => AppRuntimeSettings.agoraAppId;
String get agoraToken => AppRuntimeSettings.agoraToken;
String get agoraChannelPrefix => AppRuntimeSettings.agoraChannelPrefix;
String get oneSignalAppId => AppRuntimeSettings.oneSignalAppId;
String get timelineUrlScheme => AppRuntimeSettings.timelineUrlScheme;
String get timelineDeepLinkHost => AppRuntimeSettings.timelineDeepLinkHost;
String get timelinePackage => AppRuntimeSettings.timelinePackage;
String get appName => AppRuntimeSettings.appName;
String get appLogo => AppRuntimeSettings.appLogo.trim();
String get configuredTimelineAndroidStoreUrl =>
    AppRuntimeSettings.timelineAndroidStoreUrl.trim();
String get configuredTimelineIosStoreUrl =>
    AppRuntimeSettings.timelineIosStoreUrl.trim();
bool get hasCustomTimelineAndroidStoreUrl =>
    configuredTimelineAndroidStoreUrl.isNotEmpty;
bool get hasCustomTimelineIosStoreUrl =>
    configuredTimelineIosStoreUrl.isNotEmpty;
String get timelineAndroidStoreUrl => hasCustomTimelineAndroidStoreUrl
    ? configuredTimelineAndroidStoreUrl
    : 'https://play.google.com/store/apps/details?id=$timelinePackage';
String get timelineIosStoreUrl => hasCustomTimelineIosStoreUrl
    ? configuredTimelineIosStoreUrl
    : 'https://apps.apple.com/us/search?term=${Uri.encodeComponent(timelineDeepLinkHost)}';

bool get messengerLicenseActive => AppRuntimeSettings.messengerLicenseActive;
String get messengerLicenseStatus => AppRuntimeSettings.messengerLicenseStatus;
String get messengerLicenseMessage =>
    AppRuntimeSettings.messengerLicenseMessage;
