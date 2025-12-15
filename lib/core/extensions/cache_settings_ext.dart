import 'package:snginepro/App_Settings.dart';
/// Extension لإضافة دوال مساعدة لإدارة الكاش
extension CacheSettingsExt on AppSettings {
  /// الحصول على مدة صلاحية الكاش للفيديوهات
  static Duration get videoCacheDuration {
    return Duration(days: AppSettings.videoCacheDuration);
  }
  /// الحصول على مدة صلاحية الكاش العام
  static Duration get generalCacheDuration {
    return Duration(days: AppSettings.cacheDuration);
  }
  /// هل pre-caching مفعل
  static bool get isPreCachingEnabled {
    return AppSettings.enableVideoPreCaching;
  }
  /// عدد الفيديوهات للـ pre-cache
  static int get videoPreCacheCount {
    return AppSettings.preCacheCount;
  }
  /// هل يتم الـ pre-cache على WiFi فقط
  static bool get preCacheWifiOnly {
    return AppSettings.preCacheOnlyOnWifi;
  }
  /// حد أقصى لحجم الفيديو للـ pre-cache (بالميجابايت)
  static int get maxPreCacheSize {
    return AppSettings.maxPreCacheVideoSize;
  }
  /// الحد الأقصى لعدد الفيديوهات المخزنة
  static int get maxCachedVideosCount {
    return AppSettings.maxCachedVideosCount;
  }
}
