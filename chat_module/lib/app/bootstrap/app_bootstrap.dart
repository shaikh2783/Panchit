import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../settings.dart';
import '../../core/license/license_runtime.dart';
import '../core/controllers/app_controller.dart';
import '../core/controllers/locale_controller.dart';
import '../core/controllers/session_controller.dart';
import '../core/localization/app_translations.dart';
import '../core/storage/app_preferences.dart';
import '../core/utils/call_trace_logger.dart';
import '../data/api/api_client.dart';
import '../data/services/app_settings_service.dart';
import '../data/services/call_notification_service.dart';
import '../data/services/fcm_call_service.dart';
import '../data/services/one_signal_service.dart';
import '../features/accounts/data/services/accounts_service.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/presentation/controllers/login_controller.dart';
import '../features/auth/presentation/controllers/sign_up_controller.dart';
import '../features/calls/data/services/agora_call_service.dart';
import '../features/calls/presentation/controllers/calls_controller.dart';
import '../features/calls/presentation/controllers/incoming_call_controller.dart';
import '../features/chat/data/services/chat_service.dart';
import '../features/chat/data/services/chat_cache_store.dart';
import '../features/groups_chat/data/services/groups_chat_service.dart';
import '../features/groups_chat/presentation/controllers/groups_chat_controller.dart';
import '../features/home/data/services/stories_service.dart';
import '../features/home/presentation/controllers/home_controller.dart';
import '../features/home/presentation/controllers/profile_controller.dart';
import '../features/settings/data/services/blocked_users_service.dart';

class AppBootstrap {
  AppBootstrap._();

  static final ValueNotifier<int> restartSignal = ValueNotifier<int>(0);
  static final ValueNotifier<bool> restartInProgress = ValueNotifier<bool>(
    false,
  );

  static bool _initialized = false;
  static Future<void>? _initializing;

  /// Idempotent entry point for embedding this module inside a host app's
  /// existing process/GetX container. Safe to call every time the chat
  /// entry point is opened; only runs the real bootstrap once.
  static Future<void> ensureInitialized() {
    if (_initialized) {
      return Future<void>.value();
    }
    return _initializing ??= initializeDependencies()
        .then((_) {
          _initialized = true;
          _initializing = null;
        })
        .catchError((Object error, StackTrace stackTrace) {
          // Allow the next call to retry instead of replaying this same
          // rejected future forever.
          _initializing = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
  }

  static Future<void> initializeDependencies() async {
    unawaited(CallTraceLogger.ensureReady());
    AppRuntimeSettings.resetToDefaults();
    await LicenseRuntime.initialize();

    // GetX's translation table is a single global registry tied to the
    // host app's own GetMaterialApp. Since this module's pages are pushed
    // as routes inside that same app rather than under their own
    // GetMaterialApp, its .tr keys must be merged into that global table
    // or every string renders as its raw key.
    Get.addTranslations(AppTranslations().keys);

    final preferences = await ChatAppPreferences.create();
    await preferences.clearLegacyApiRuntimeCache();

    final localeController = ChatLocaleController(preferences);
    await localeController.loadSavedLocale();

    final apiClient = ChatModuleApiClient(preferences);
    final appSettingsService = AppSettingsService(apiClient);
    // Runs in the background instead of blocking the messenger's first open
    // on a network round trip: every field it sets has a safe built-in
    // default (see AppRuntimeSettings.resetToDefaults above), so the UI can
    // render before this resolves and just picks up the real values once it
    // lands.
    unawaited(
      appSettingsService
          .fetchAppSettings()
          .then((appSettings) => appSettings.applyToRuntime())
          .catchError((_) {
            // Keep built-in defaults when remote app settings are unavailable.
          }),
    );

    final authService = AuthService(apiClient, preferences);
    final accountsService = AccountsService(apiClient);
    final chatService = ChatService(apiClient);
    final chatCacheStore = ChatCacheStore();
    final groupsChatService = GroupsChatService(apiClient);
    final storiesService = StoriesService(apiClient);
    final blockedUsersService = BlockedUsersService(apiClient);
    final oneSignalService = OneSignalService(apiClient, preferences);
    final fcmCallService = FcmCallService(apiClient, preferences);
    const agoraCallService = AgoraCallService();

    await CallNotificationService.initialize();

    Get.put(preferences, permanent: true);
    Get.put(localeController, permanent: true);
    Get.put(AppController(preferences), permanent: true);
    Get.put(apiClient, permanent: true);
    Get.put(appSettingsService, permanent: true);
    Get.put(oneSignalService, permanent: true);
    Get.put(fcmCallService, permanent: true);
    Get.put(authService, permanent: true);
    Get.put(accountsService, permanent: true);
    Get.put(chatService, permanent: true);
    Get.put(chatCacheStore, permanent: true);
    Get.put(groupsChatService, permanent: true);
    Get.put(storiesService, permanent: true);
    Get.put(blockedUsersService, permanent: true);
    Get.put(agoraCallService, permanent: true);

    final sessionController = Get.put(
      SessionController(
        authService,
        preferences,
        oneSignalService,
        fcmCallService,
      ),
      permanent: true,
    );

    Get.put(LoginController(authService, sessionController), permanent: true);
    Get.put(SignUpController(authService, sessionController), permanent: true);
    Get.put(
      HomeController(chatService, preferences, chatCacheStore),
      permanent: true,
    );
    Get.put(
      GroupsChatController(groupsChatService, preferences),
      permanent: true,
    );
    Get.put(
      ProfileController(accountsService, sessionController, preferences),
      permanent: true,
    );
    Get.put(
      IncomingCallController(
        chatService: chatService,
        sessionController: sessionController,
      ),
      permanent: true,
    );
    Get.put(CallsController(chatService, preferences), permanent: true);

    await fcmCallService.initialize();
  }

  static Future<void> restartApp() async {
    if (restartInProgress.value) {
      return;
    }
    restartInProgress.value = true;
    try {
      await WidgetsBinding.instance.endOfFrame;
      Get.reset();
      await initializeDependencies();
      restartSignal.value++;
    } finally {
      restartInProgress.value = false;
    }
  }
}
