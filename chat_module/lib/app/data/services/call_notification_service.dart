import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/app_preferences.dart';
import '../../../settings.dart';

class CallNotificationService {
  CallNotificationService._();

  static const String _channelId = 'incoming_calls_v3';
  static const String _channelName = 'Incoming Calls';
  static const String _channelDescription =
      'Shows incoming audio and video calls';
  static const RawResourceAndroidNotificationSound _notificationSound =
      RawResourceAndroidNotificationSound('incoming_call_ringtone');
  static const int _incomingCallTimeoutMs = 60000;
  static const MethodChannel _permissionsChannel = MethodChannel(
    'messenger/call_permissions',
  );
  static const String acceptAction = 'ACCEPT_CALL_NOTIFICATION';
  static const String declineAction = 'DECLINE_CALL_NOTIFICATION';
  static const String _silenceCallRingingMethod = 'silenceCallRinging';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final Int64List _callVibrationPattern = Int64List.fromList(<int>[
    0,
    800,
    450,
    800,
    450,
    1100,
  ]);

  static bool _initialized = false;

  static void _logInfo(String message) {
    if (callLoggingEnabled) {
      debugPrint('[CALL NOTIFICATION] $message');
    }
  }

  static void _logError(String message) {
    if (callLoggingEnabled) {
      debugPrint('[CALL NOTIFICATION] $message');
    }
  }

  static Future<void> initialize() async {
    if (!Platform.isAndroid || _initialized) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_call_notification'),
    );

    await _plugin.initialize(
      settings,
      onSelectNotification: _handleNotificationSelection,
    );

    await _restoreLaunchPayloadIfNeeded();

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            _channelDescription,
            importance: Importance.max,
            playSound: true,
            sound: _notificationSound,
            enableVibration: true,
            vibrationPattern: _callVibrationPattern,
            showBadge: false,
          ),
        );

    _initialized = true;
  }

  static Future<void> showIncomingCallNotification(
    Map<String, dynamic> payload,
  ) async {
    if (Platform.isIOS) {
      await _showIosIncomingCall(payload);
      return;
    }

    if (!Platform.isAndroid) {
      return;
    }

    await initialize();

    final normalizedPayload = Map<String, dynamic>.from(payload);
    normalizedPayload['_call_action_accept_label'] = _defaultAcceptLabel();
    normalizedPayload['_call_action_decline_label'] = _defaultDeclineLabel();

    final callId = _parseInt(normalizedPayload['call_id']);
    final callerName = _resolveCallerName(normalizedPayload);
    final isVideoCall = _parseBool(normalizedPayload['is_video_call']);
    final isGroupInvite =
        normalizedPayload['event']?.toString() == 'webrtc_call_invite' ||
        normalizedPayload['invite_type']?.toString() == 'webrtc_group_call';
    final participantNames =
        normalizedPayload['participant_names']?.toString().trim() ?? '';
    final status = isGroupInvite
        ? (isVideoCall ? 'Group video call invite' : 'Group voice call invite')
        : (isVideoCall ? 'Incoming video call' : 'Incoming voice call');
    final title = callerName.isEmpty ? 'New incoming call' : callerName;
    final body = isGroupInvite && participantNames.isNotEmpty
        ? '$status with $participantNames'
        : status;
    final largeIcon = await _loadCallerAvatarBitmap(
      normalizedPayload['caller_picture']?.toString() ??
          normalizedPayload['from_user_picture']?.toString(),
    );

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        _channelDescription,
        icon: 'ic_call_notification',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: _notificationSound,
        enableVibration: true,
        vibrationPattern: _callVibrationPattern,
        category: 'call',
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        ticker: status,
        timeoutAfter: _incomingCallTimeoutMs,
        when: DateTime.now().millisecondsSinceEpoch,
        usesChronometer: true,
        visibility: NotificationVisibility.public,
        largeIcon: largeIcon,
        additionalFlags: Int32List.fromList(<int>[4]),
      ),
    );

    await _plugin.show(
      callId > 0 ? callId : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(normalizedPayload),
    );

    _logInfo('showed Android full-screen incoming call notification');
  }

  static Future<void> cancelIncomingCallNotification(int callId) async {
    if (Platform.isIOS) {
      await _endIosIncomingCall(callId);
      return;
    }

    if (!Platform.isAndroid || callId <= 0) {
      return;
    }

    await initialize();
    await _plugin.cancel(callId);
  }

  static Future<void> silenceIncomingCallRinging(int callId) async {
    if (Platform.isIOS) {
      if (callId > 0) {
        await _endIosIncomingCall(callId);
      }
      return;
    }

    if (!Platform.isAndroid) {
      return;
    }

    if (callId > 0) {
      await cancelIncomingCallNotification(callId);
    }

    try {
      await _permissionsChannel.invokeMethod<bool>(
        _silenceCallRingingMethod,
        <String, dynamic>{'call_id': callId},
      );
    } catch (error) {
      _logError('failed to silence Android call ringing: $error');
    }
  }

  static Future<void> _showIosIncomingCall(Map<String, dynamic> payload) async {
    try {
      await _permissionsChannel.invokeMethod<bool>(
        'showIncomingCall',
        Map<String, dynamic>.from(payload),
      );
    } catch (error) {
      _logError('failed to show iOS CallKit incoming call: $error');
    }
  }

  static Future<void> _endIosIncomingCall(int callId) async {
    try {
      await _permissionsChannel.invokeMethod<bool>('endIncomingCall', {
        'call_id': callId,
      });
    } catch (error) {
      _logError('failed to end iOS CallKit incoming call: $error');
    }
  }

  static Future<void> ensureFullScreenIntentPermission(
    ChatAppPreferences preferences, {
    bool allowRepeatPrompt = false,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    final canUseFullScreenIntent = await _canUseFullScreenIntent();
    if (canUseFullScreenIntent) {
      return;
    }

    if (!allowRepeatPrompt &&
        preferences.hasFullScreenIntentPermissionPrompted()) {
      _logInfo('full-screen intent permission was already prompted');
      return;
    }

    final approved = await _showPermissionRationaleDialog(
      title: _isArabicLocale()
          ? 'السماح بإظهار المكالمات الواردة'
          : 'Allow incoming call pop-up',
      message: _isArabicLocale()
          ? 'لإظهار المكالمات الواردة بشكل واضح وموثوق، يحتاج التطبيق إلى السماح بعرض تنبيه المكالمة على كامل الشاشة. يمكنك المتابعة الآن أو لاحقًا من الإعدادات.'
          : 'To show incoming calls clearly and reliably, the app needs permission to display the incoming call alert in full screen. You can continue now or do this later in settings.',
      confirmLabel: _isArabicLocale() ? 'فتح الإعدادات' : 'Open settings',
      cancelLabel: _isArabicLocale() ? 'ليس الآن' : 'Not now',
    );
    if (!approved) {
      return;
    }

    final openedSettings = await _openFullScreenIntentSettings();
    if (openedSettings) {
      await preferences.setFullScreenIntentPermissionPrompted(true);
      _logInfo('opened full-screen intent settings');
    }
  }

  static Future<bool> canShowFullScreenIncomingCalls() {
    return _canUseFullScreenIntent();
  }

  static Future<bool> openFullScreenIncomingCallSettings() {
    return _openFullScreenIntentSettings();
  }

  static Future<void> ensureBatteryOptimizationExemption(
    ChatAppPreferences preferences,
  ) async {
    if (!Platform.isAndroid) {
      return;
    }

    final isIgnoringBatteryOptimizations =
        await _isIgnoringBatteryOptimizations();
    if (isIgnoringBatteryOptimizations) {
      return;
    }

    if (preferences.hasBatteryOptimizationPrompted()) {
      _logInfo('battery optimization settings were already prompted');
      return;
    }

    final approved = await _showPermissionRationaleDialog(
      title: _isArabicLocale()
          ? 'السماح بوصول المكالمات في الخلفية'
          : 'Allow background call delivery',
      message: _isArabicLocale()
          ? 'لتحسين وصول المكالمات الواردة عندما يكون التطبيق في الخلفية أو عند إغلاق الشاشة، يفضّل جعل التطبيق غير مقيّد ضمن إعدادات البطارية. هذا يساعد على استقبال المكالمات بشكل أفضل، ويمكنك تخطي هذه الخطوة إذا رغبت.'
          : 'To improve incoming call delivery when the app is in the background or when the screen is off, it is recommended to allow the app to run without battery restrictions. This helps incoming calls arrive more reliably, and you can skip this step if you prefer.',
      confirmLabel: _isArabicLocale() ? 'فتح الإعدادات' : 'Open settings',
      cancelLabel: _isArabicLocale() ? 'ليس الآن' : 'Not now',
    );
    if (!approved) {
      return;
    }

    final openedSettings = await _openBatteryOptimizationSettings();
    if (openedSettings) {
      await preferences.setBatteryOptimizationPrompted(true);
      _logInfo('opened battery optimization settings');
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() {
    return _isIgnoringBatteryOptimizations();
  }

  static Future<bool> openBatteryOptimizationSettingsPage() {
    return _openBatteryOptimizationSettings();
  }

  static Future<void> _handleNotificationSelection(String? payload) async {
    final normalizedPayload = payload?.trim() ?? '';
    if (normalizedPayload.isEmpty) {
      return;
    }

    await _persistPendingPayload(normalizedPayload);
  }

  static Future<void> _restoreLaunchPayloadIfNeeded() async {
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchedFromNotification =
          launchDetails?.didNotificationLaunchApp ?? false;
      final payload = launchDetails?.payload?.trim() ?? '';
      if (!launchedFromNotification || payload.isEmpty) {
        return;
      }

      await _persistPendingPayload(payload);
      _logInfo('restored pending call payload from app launch');
    } catch (error) {
      _logError('failed to restore launch payload: $error');
    }
  }

  static Future<void> _persistPendingPayload(String payload) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        ChatAppPreferences.pendingIncomingCallPayloadKey,
        payload,
      );
      _logInfo('restored pending call payload from notification tap');
    } catch (error) {
      _logError('failed to restore notification payload: $error');
    }
  }

  static Future<bool> _canUseFullScreenIntent() async {
    try {
      final result = await _permissionsChannel.invokeMethod<bool>(
        'canUseFullScreenIntent',
      );
      return result ?? true;
    } catch (error) {
      _logError('failed to check full-screen intent permission: $error');
      return true;
    }
  }

  static Future<bool> _openFullScreenIntentSettings() async {
    try {
      final result = await _permissionsChannel.invokeMethod<bool>(
        'openFullScreenIntentSettings',
      );
      return result ?? false;
    } catch (error) {
      _logError('failed to open full-screen intent settings: $error');
      return false;
    }
  }

  static Future<bool> _isIgnoringBatteryOptimizations() async {
    try {
      final result = await _permissionsChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? true;
    } catch (error) {
      _logError('failed to check battery optimization exemption: $error');
      return true;
    }
  }

  static Future<bool> _openBatteryOptimizationSettings() async {
    try {
      final result = await _permissionsChannel.invokeMethod<bool>(
        'openBatteryOptimizationSettings',
      );
      return result ?? false;
    } catch (error) {
      _logError('failed to open battery optimization settings: $error');
      return false;
    }
  }

  static Future<bool> _showPermissionRationaleDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final context = Get.context ?? Get.overlayContext ?? Get.key.currentContext;
    if (context == null) {
      _logInfo('permission rationale skipped because context is null');
      return false;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          textAlign: _isArabicLocale() ? TextAlign.right : TextAlign.left,
        ),
        content: Text(
          message,
          textAlign: _isArabicLocale() ? TextAlign.right : TextAlign.left,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmLabel),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }

  static Future<LaunchCallAction?> consumeLaunchCallAction() async {
    try {
      final result = await _permissionsChannel.invokeMapMethod<String, dynamic>(
        'getLaunchCallAction',
      );
      if (result == null || result.isEmpty) {
        return null;
      }

      final action = result['action']?.toString().trim() ?? '';
      final payload = result['payload']?.toString().trim() ?? '';
      if (action.isEmpty) {
        return null;
      }

      await _permissionsChannel.invokeMethod<bool>('clearLaunchCallAction');
      return LaunchCallAction(action: action, payload: payload);
    } catch (error) {
      _logError('failed to consume launch call action: $error');
      return null;
    }
  }

  static Future<String?> getVoipPushToken() async {
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final result = await _permissionsChannel.invokeMethod<String>(
        'getVoipPushToken',
      );
      final token = result?.trim() ?? '';
      if (token.isEmpty) {
        return null;
      }
      return token;
    } catch (error) {
      _logError('failed to read iOS VoIP push token: $error');
      return null;
    }
  }

  static String _resolveCallerName(Map<String, dynamic> payload) {
    final fullName = payload['from_user_fullname']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final userName = payload['from_user_name']?.toString().trim() ?? '';
    if (userName.isNotEmpty) {
      return userName;
    }

    return '';
  }

  static String _defaultAcceptLabel() {
    return _isArabicLocale() ? 'رد' : 'Answer';
  }

  static String _defaultDeclineLabel() {
    return _isArabicLocale() ? 'رفض' : 'Decline';
  }

  static bool _isArabicLocale() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode
        .toLowerCase();
    return code == 'ar';
  }

  static Future<AndroidBitmap<Object>?> _loadCallerAvatarBitmap(
    String? rawUrl,
  ) async {
    final imageUrl = rawUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return null;
    }

    HttpClient? client;
    try {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null) {
        return null;
      }

      client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bytes = await consolidateHttpClientResponseBytes(
        response,
      ).timeout(const Duration(seconds: 4));
      if (bytes.isEmpty) {
        return null;
      }

      return ByteArrayAndroidBitmap(bytes);
    } catch (error) {
      _logError('failed to load caller avatar for notification: $error');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static bool _parseBool(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class LaunchCallAction {
  const LaunchCallAction({required this.action, required this.payload});

  final String action;
  final String payload;

  bool get isAccept => action == CallNotificationService.acceptAction;
  bool get isDecline => action == CallNotificationService.declineAction;
}
