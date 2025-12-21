import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snginepro/app/app.dart';
import 'package:snginepro/App_Settings.dart' show AppSettings;
import 'package:snginepro/core/SharedPreferences.dart';
import 'package:snginepro/core/theme/theme_controller.dart';
import 'package:snginepro/core/localization/localization_controller.dart';
import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/core/services/reactions_api_service.dart';
import 'package:snginepro/core/services/reactions_service.dart';
import 'package:snginepro/core/services/notification_navigation_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:snginepro/features/settings/data/models/seeting.dart';
import 'package:snginepro/license_fluttercrafters.dart';
import 'core/config/app_config.dart' show appConfig;
List cfgP = [
  {"docs": ameen},
];
List GetSetList = [];
String configCfgP(String key) {
  try {
    if (cfgP.isEmpty || cfgP[0] is! Map) {
      throw Exception('cfgP is not initialized');
    }
    final keyMappings = cfgP[0]['key_mappings'];
    String actualKey = key;
    if (keyMappings is Map && keyMappings.containsKey(key)) {
      actualKey = keyMappings[key]?.toString() ?? key;
    }
    final endpoints = cfgP[0]['endpoints'];
    if (endpoints == null) {
      throw Exception('endpoints not found in cfgP');
    }
    if (endpoints is Map && endpoints.containsKey(actualKey)) {
      return endpoints[actualKey]?.toString() ?? '';
    }
    throw Exception('Endpoint "$key" (mapped to "$actualKey") not found in encrypted config');
  } catch (e) {
    return '';
  }
}
bool _oneSignalInitialized = false;
bool _oneSignalHandlersSet = false;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await ImageGrids(); // تحميل الصور الافتراضية
  final posts = await SharedP.Get('posts');
  postsconst(posts);
  // Load SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  // Initialize API Client
  final apiClient = ApiClient(config: appConfig);
  // Initialize OneSignal with app settings from API
  await _initializeOneSignal(apiClient);
  // Initialize ReactionsService
  final reactionsApiService = ReactionsApiService(apiClient: apiClient);
  ReactionsService.instance.initialize(reactionsApiService);
  // Fetch reactions in the background (don't wait for completion)
  ReactionsService.instance
      .loadReactions()
      .then((reactions) {
      })
      .catchError((e) {
      });
  // Register Controllers with GetX
  Get.put(ThemeController());
  Get.put(LocalizationController());
  // Register ApiClient for dependency injection
  Get.put(apiClient);
  runApp(App(sharedPreferences: sharedPreferences));
}
/// Initialize OneSignal SDK
Future<void> _initializeOneSignal(ApiClient apiClient) async {
  try {
    if (_oneSignalInitialized) {
      // Ensure handlers are set once
      _setupNotificationHandlers();
      return;
    }
    // استخدام OneSignal App ID من AppSettings
    final oneSignalAppId = AppSettings.oneSignalAppId;
    // Remove this method to debug issues
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // Set app ID directly
    OneSignal.initialize(oneSignalAppId);
    // Request notification permission
    OneSignal.Notifications.requestPermission(true);
    // Setup notification handlers
    _setupNotificationHandlers();
    _oneSignalInitialized = true;
  } catch (e) {

  }
}
/// Setup notification click and receive handlers
void _setupNotificationHandlers() {
  if (_oneSignalHandlersSet) {
    return;
  }
  _oneSignalHandlersSet = true;
  // استمع لتغييرات Subscription ID
  OneSignal.User.pushSubscription.addObserver((state) {
    final playerId = state.current.id;
    if (playerId != null && playerId.isNotEmpty) {
      // يمكن حفظ Player ID هنا للاستخدام لاحقاً
    }
  });
  // Handle notification opened (clicked)
  // Deduplicate rapid repeated clicks from the same notification
  String? lastClickedId;
  DateTime? lastClickTime;
  OneSignal.Notifications.addClickListener((event) {
    final now = DateTime.now();
    if (lastClickedId == event.notification.notificationId &&
        lastClickTime != null &&
        now.difference(lastClickTime!).inMilliseconds < 800) {
      return;
    }
    lastClickedId = event.notification.notificationId;
    lastClickTime = now;
    final additional = event.notification.additionalData;
    final launchUrl = event.notification.launchUrl;
    final data = <String, dynamic>{
      if (additional != null) ...additional,
      if (launchUrl != null && launchUrl.isNotEmpty) 'url': launchUrl,
    };
    if (data.isEmpty) {
      return;
    }
    NotificationNavigationService.handleNotification(data);
  });
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    
    // Prevent default display to avoid duplicates, then display exactly once
    event.preventDefault();
    event.notification.display();
  });
}
Future<void> ImageGrids() async {
  cfgP.clear();
  await SharedP.Save('posts', ameen);
}
