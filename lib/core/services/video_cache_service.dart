import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:snginepro/App_Settings.dart';

/// خدمة إدارة كاش الفيديوهات مع دعم pre-caching
/// تستخدم الإعدادات من AppSettings
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();

  factory VideoCacheService() {
    return _instance;
  }

  VideoCacheService._internal();

  /// قائمة الفيديوهات المخزنة مؤقتاً
  final Set<String> _cachedVideos = {};

  /// عدد الفيديوهات المخزنة حالياً
  int get cachedCount => _cachedVideos.length;

  /// هل الفيديو مخزن مؤقتاً
  bool isCached(String videoUrl) => _cachedVideos.contains(videoUrl);

  /// pre-cache فيديو واحد
  Future<void> preCacheVideo(String videoUrl, {String? cacheKey}) async {
    if (!AppSettings.enableVideoPreCaching) return;

    // تجنب الحفظ المكرر
    if (_cachedVideos.contains(videoUrl)) {
      return;
    }

    try {
      await CachedVideoPlayerPlus.preCacheVideo(
        Uri.parse(videoUrl),
        invalidateCacheIfOlderThan:
            Duration(days: AppSettings.videoCacheDuration),
        cacheKey: cacheKey,
      );

      // أضف إلى قائمة المخزن مؤقتاً
      _cachedVideos.add(videoUrl);

      // إذا تجاوزنا الحد الأقصى، احذف الأقدم
      if (_cachedVideos.length > AppSettings.maxCachedVideosCount) {
        // في التطبيق الحقيقي، يمكن إدارة أولويات الحذف
        _cachedVideos.clear();
      }
    } catch (e) {

    }
  }

  /// pre-cache عدة فيديوهات
  Future<void> preCacheVideos(List<String> videoUrls) async {
    for (final url in videoUrls) {
      await preCacheVideo(url);
    }
  }

  /// حذف فيديو من الكاش
  Future<void> removeCachedVideo(String videoUrl) async {
    try {
      await CachedVideoPlayerPlus.removeFileFromCache(Uri.parse(videoUrl));
      _cachedVideos.remove(videoUrl);
    } catch (e) {

    }
  }

  /// حذف فيديو من الكاش باستخدام مفتاح مخصص
  Future<void> removeCachedVideoByKey(String cacheKey) async {
    try {
      await CachedVideoPlayerPlus.removeFileFromCacheByKey(cacheKey);
    } catch (e) {

    }
  }

  /// حذف جميع الفيديوهات المخزنة
  Future<void> clearAllCache() async {
    try {
      await CachedVideoPlayerPlus.clearAllCache();
      _cachedVideos.clear();
    } catch (e) {

    }
  }

  /// الحصول على إعدادات الكاش الحالية
  Map<String, dynamic> getCacheSettings() {
    return {
      'enabled': AppSettings.enableVideoPreCaching,
      'cacheDuration': '${AppSettings.videoCacheDuration} أيام',
      'preCacheCount': AppSettings.preCacheCount,
      'maxVideoSize': '${AppSettings.maxPreCacheVideoSize} MB',
      'maxCachedCount': AppSettings.maxCachedVideosCount,
      'wifiOnly': AppSettings.preCacheOnlyOnWifi,
      'currentCachedCount': _cachedVideos.length,
    };
  }
}
