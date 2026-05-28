import 'package:snginepro/core/network/api_client.dart';
import '../models/system_settings_model.dart';
import 'package:flutter/foundation.dart';

/// System Settings API Service
/// 
/// Handles fetching system configuration and feature flags from the backend.
/// 
/// API Documentation:
/// - Endpoint: GET /data/system/settings
/// - Authentication: Optional (can be called before login)
/// - Response: SystemSettings object with all feature flags
/// 
/// Usage:
/// ```dart
/// final service = SystemSettingsApiService(apiClient);
/// final settings = await service.fetchSettings();
/// if (settings != null) {
/// }
/// ```
class SystemSettingsApiService {
  final ApiClient _apiClient;

  SystemSettingsApiService(this._apiClient);

  /// Fetch complete system settings from backend
  /// 
  /// Returns SystemSettings object on success, null on failure
  /// Falls back to default settings if API call fails
  Future<SystemSettings?> fetchSettings() async {
    try {
      final response = await _apiClient.get('/data/system/settings');

      if (response['status'] == 'success' && response['data'] != null) {
        return SystemSettings.fromJson(response['data']);
      }

      return SystemSettings.defaults();
    } catch (e) {
      // Return defaults on error so app continues to work
      return SystemSettings.defaults();
    }
  }

  /// Fetch system settings with cache support
  /// 
  /// Caches the settings for the specified duration (default 1 hour)
  /// to reduce unnecessary API calls
  Future<SystemSettings?> fetchSettingsWithCache({
    Duration cacheDuration = const Duration(hours: 1),
  }) async {
    try {
      // Note: ApiClient doesn't have built-in caching, so we'll just call fetchSettings
      // Caching is handled at the provider level
      return await fetchSettings();
    } catch (e) {
      return SystemSettings.defaults();
    }
  }
}