import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../network/api_client.dart';
import '../../main.dart' show configCfgP;
import 'app_config_model.dart';

/// خدمة إدارة إعدادات التطبيق الديناميكية
/// تستخدم ApiClient الموجود لجلب الإعدادات من الخادم
class DynamicAppConfigService {
  final ApiClient _apiClient;
  
  static const String _cacheKey = 'dynamic_app_config_cache';
  static const String _lastUpdateKey = 'dynamic_app_config_last_update';
  static const Duration _cacheExpiry = Duration(hours: 6);

  DynamicAppConfigService(this._apiClient);

  /// الحصول على إعدادات التطبيق الديناميكية
  Future<AppConfig?> getAppConfig({bool forceRefresh = false}) async {
    try {
      if (kDebugMode) {

      }
      
      // إذا لم يطلب تحديث إجباري، جرب الكاش أولاً
      if (!forceRefresh) {
        final cachedConfig = await _getCachedConfig();
        if (cachedConfig != null) {
          if (kDebugMode) {

          }
          return cachedConfig;
        }
      } else {
        if (kDebugMode) {

        }
      }

      // جلب الإعدادات من الخادم باستخدام ApiClient
      final config = await _fetchConfigFromServer();
      if (config != null) {
        await _cacheConfig(config);
        if (kDebugMode) {

        }
        return config;
      }

      // إذا فشل جلب من الخادم، جرب الكاش حتى لو انتهت صلاحيته
      final fallbackConfig = await _getCachedConfig(ignoreCacheExpiry: true);
      if (fallbackConfig != null) {
        if (kDebugMode) {

        }
        return fallbackConfig;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {

      }
      // في حالة الخطأ، جرب الكاش
      return await _getCachedConfig(ignoreCacheExpiry: true);
    }
  }

  /// جلب الإعدادات من الخادم باستخدام ApiClient الموجود
  Future<AppConfig?> _fetchConfigFromServer() async {
    try {
      if (kDebugMode) {

      }

      // استخدام endpoint الموجود في config.md
      final response = await _apiClient.get(configCfgP('config'));
      
      if (response.containsKey('data')) {
        return AppConfig.fromJson(response['data']);
      } else {
        return AppConfig.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) {

      }
      return null;
    }
  }

  /// جلب الإعدادات من الكاش المحلي
  Future<AppConfig?> _getCachedConfig({bool ignoreCacheExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final lastUpdateString = prefs.getString(_lastUpdateKey);

      if (cachedJson != null) {
        // التحقق من انتهاء صلاحية الكاش
        if (!ignoreCacheExpiry && lastUpdateString != null) {
          final lastUpdate = DateTime.parse(lastUpdateString);
          if (DateTime.now().difference(lastUpdate) > _cacheExpiry) {
            if (kDebugMode) {

            }
            return null;
          }
        }

        final jsonData = json.decode(cachedJson);
        return AppConfig.fromJson(jsonData);
      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
    return null;
  }

  /// حفظ الإعدادات في الكاش المحلي
  Future<void> _cacheConfig(AppConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(config.toJson());
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      if (kDebugMode) {

      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }

  /// مسح الكاش المحلي
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastUpdateKey);
      
      if (kDebugMode) {

      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }

  /// التحقق من صلاحية الكاش
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateString = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateString != null) {
        final lastUpdate = DateTime.parse(lastUpdateString);
        return DateTime.now().difference(lastUpdate) <= _cacheExpiry;
      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
    return false;
  }

  /// الحصول على تاريخ آخر تحديث للكاش
  Future<DateTime?> getLastCacheUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateString = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateString != null) {
        return DateTime.parse(lastUpdateString);
      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
    return null;
  }

  /// تحديث إعدادات معينة (إذا كان API يدعم ذلك)
  Future<bool> updateSettings(Map<String, dynamic> updates) async {
    try {
      if (kDebugMode) {

      }

      // استخدام endpoint لتحديث الإعدادات
      await _apiClient.post(configCfgP('config_update'), body: updates);
      
      // إعادة جلب الإعدادات الكاملة بعد التحديث
      final updatedConfig = await _fetchConfigFromServer();
      if (updatedConfig != null) {
        await _cacheConfig(updatedConfig);
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {

      }
      return false;
    }
  }
}
