import 'package:flutter/foundation.dart';
import '../data/models/system_settings_model.dart';
import '../data/services/system_settings_api_service.dart';

/// System Settings Provider
/// 
/// Global state management for system configuration and feature flags.
/// This provider is initialized on app startup and provides access to
/// system settings throughout the application.
/// 
/// Features:
/// - Fetches and caches system settings
/// - Provides feature flag checks
/// - Auto-refreshes settings periodically
/// - Falls back to defaults on error
/// 
/// Usage:
/// ```dart
/// // In main.dart initialization:
/// await systemSettingsProvider.initialize();
/// 
/// // In widgets:
/// final provider = context.watch<SystemSettingsProvider>();
/// if (provider.settings.socialFeatures.friendsEnabled) {
///   // Show friends button
/// }
/// 
/// // Quick checks:
/// if (provider.isFriendsEnabled) {
///   // Show friends feature
/// }
/// ```
class SystemSettingsProvider with ChangeNotifier {
  final SystemSettingsApiService _apiService;

  SystemSettings _settings = SystemSettings.defaults();
  bool _isLoading = false;
  DateTime? _lastFetched;

  SystemSettingsProvider(this._apiService);

  /// Current system settings
  SystemSettings get settings => _settings;

  /// Whether settings are being fetched
  bool get isLoading => _isLoading;

  /// When settings were last fetched
  DateTime? get lastFetched => _lastFetched;

  // Quick access feature flags
  bool get isFriendsEnabled => _settings.socialFeatures.friendsEnabled;
  bool get isFollowersEnabled => _settings.socialFeatures.followersEnabled;
  bool get isMessagingEnabled => _settings.socialFeatures.messagingEnabled;
  bool get isStoriesEnabled => _settings.socialFeatures.storiesEnabled;
  bool get isGroupsEnabled => _settings.contentFeatures.groupsEnabled;
  bool get isPagesEnabled => _settings.contentFeatures.pagesEnabled;
  bool get isEventsEnabled => _settings.contentFeatures.eventsEnabled;
  bool get isMarketplaceEnabled => _settings.communityFeatures.marketplaceEnabled;
  bool get isWalletEnabled => _settings.monetizationFeatures.walletEnabled;
  bool get isLiveStreamingEnabled => _settings.communicationFeatures.liveStreamingEnabled;

  /// Initialize and fetch settings on app startup
  /// 
  /// This should be called in main.dart before runApp()
  /// ```dart
  /// await systemSettingsProvider.initialize();
  /// ```
  Future<void> initialize() async {
    await fetchSettings();
  }

  /// Fetch system settings from API
  /// 
  /// This updates the settings and notifies listeners
  /// Uses cached version if last fetch was less than 1 hour ago
  Future<void> fetchSettings({bool force = false}) async {
    // Skip if recently fetched and not forcing
    if (!force && _lastFetched != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetched!);
      if (timeSinceLastFetch.inMinutes < 60) {
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final fetchedSettings = await _apiService.fetchSettingsWithCache();

      if (fetchedSettings != null) {
        _settings = fetchedSettings;
        _lastFetched = DateTime.now();
      } else {
      }
    } catch (e) {
      // Keep existing settings or defaults
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh settings (force fetch from API)
  Future<void> refresh() async {
    await fetchSettings(force: true);
  }

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'friends':
        return isFriendsEnabled;
      case 'followers':
        return isFollowersEnabled;
      case 'messaging':
        return isMessagingEnabled;
      case 'stories':
        return isStoriesEnabled;
      case 'groups':
        return isGroupsEnabled;
      case 'pages':
        return isPagesEnabled;
      case 'events':
        return isEventsEnabled;
      case 'marketplace':
        return isMarketplaceEnabled;
      case 'wallet':
        return isWalletEnabled;
      case 'livestreaming':
        return isLiveStreamingEnabled;
      default:
        return false;
    }
  }
}
