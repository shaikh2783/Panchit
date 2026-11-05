import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'notification_navigation_service.dart';

/// Listens for incoming Android App Links / iOS Universal Links (and any
/// custom-scheme link such as `sngine://`) and routes them through
/// [NotificationNavigationService], which already knows how to open the
/// right screen for a given path (posts, reels, profiles, competitions...).
class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;
  static bool _initialized = false;

  /// Call once, after the app's navigator is ready (e.g. right alongside
  /// [NotificationNavigationService.markAppReady]).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // The link that launched the app from a cold start, if any.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        NotificationNavigationService.handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('⚠️ DeepLinkService: failed to read initial link: $e');
    }

    // Links opened while the app is already running (foreground/background).
    _subscription = _appLinks.uriLinkStream.listen(
      NotificationNavigationService.handleDeepLink,
      onError: (Object e) {
        debugPrint('⚠️ DeepLinkService: link stream error: $e');
      },
    );
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
