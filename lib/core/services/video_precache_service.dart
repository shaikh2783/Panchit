import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:snginepro/App_Settings.dart';

/// خدمة لـ pre-cache الفيديوهات قبل تشغيلها
/// تحفظ الفيديوهات في الكاش بشكل مسبق لضمان التشغيل السريع
class VideoPrecacheService {
  static final VideoPrecacheService _instance = VideoPrecacheService._internal();

  factory VideoPrecacheService() {
    return _instance;
  }

  VideoPrecacheService._internal();

  final Set<String> _cachingUrls = {}; // تتبع الفيديوهات قيد الحفظ
  final Map<String, DateTime> _cachedUrls = {}; // الفيديوهات المحفوظة بالفعل مع وقت الحفظ (LRU)
  
  // ✅ Memory management: Limit maximum concurrent caching operations
  static const int _maxConcurrentCaching = 2;
  int _currentCachingCount = 0;

  /// التحقق من وجود الفيديو في الكاش
  bool isCached(String url) => _cachedUrls.containsKey(url);

  /// التحقق من حالة حفظ الفيديو
  bool isCaching(String url) => _cachingUrls.contains(url);

  /// حفظ فيديو مسبقاً
  /// 
  /// Parameters:
  /// - [url]: رابط الفيديو
  /// - [cacheValidDays]: عدد أيام صلاحية الكاش (افتراضي: من AppSettings)
  /// - [cacheKey]: مفتاح مخصص للكاش
  Future<void> precacheVideo(
    String url, {
    int? cacheValidDays,
    String? cacheKey,
  }) async {
    // التحقق من تفعيل pre-caching من AppSettings
    if (!AppSettings.enableVideoPreCaching) {
      return;
    }

    // تجنب حفظ نفس الفيديو مرتين
    if (_cachedUrls.containsKey(url) || _cachingUrls.contains(url)) {
      // Update access time for LRU
      if (_cachedUrls.containsKey(url)) {
        _cachedUrls[url] = DateTime.now();
      }
      return;
    }
    
    // ✅ Limit concurrent caching operations to prevent memory exhaustion
    if (_currentCachingCount >= _maxConcurrentCaching) {
      if (kDebugMode) {

      }
      return;
    }
    
    // ✅ Check cache size limit and cleanup old entries
    if (_cachedUrls.length >= AppSettings.maxCachedVideosCount) {
      _cleanupOldestCache();
    }

    try {
      _cachingUrls.add(url);
      _currentCachingCount++;
      
      // استخدم القيمة من AppSettings إذا لم تُحدد
      final cacheDays = cacheValidDays ?? AppSettings.videoCacheDuration;
      
      if (kDebugMode) {

      }

      // بدء حفظ الفيديو
      await CachedVideoPlayerPlus.preCacheVideo(
        Uri.parse(url),
        invalidateCacheIfOlderThan: Duration(days: cacheDays),
        cacheKey: cacheKey,
      );

      _cachedUrls[url] = DateTime.now();
      _cachingUrls.remove(url);
      _currentCachingCount--;

      if (kDebugMode) {

      }
    } catch (e) {
      _cachingUrls.remove(url);
      _currentCachingCount--;
      if (kDebugMode) {

      }
    }
  }

  /// حفظ عدة فيديوهات بشكل متوازي
  Future<void> precacheVideos(
    List<String> urls, {
    int cacheValidDays = 7,
  }) async {
    // ✅ Process sequentially to avoid memory spikes
    for (final url in urls) {
      await precacheVideo(url, cacheValidDays: cacheValidDays);
    }
  }
  
  /// ✅ Cleanup oldest cached videos (LRU strategy)
  void _cleanupOldestCache() {
    if (_cachedUrls.isEmpty) return;
    
    // Sort by access time (oldest first)
    final sortedEntries = _cachedUrls.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest 20% of cache
    final removeCount = (_cachedUrls.length * 0.2).ceil();
    for (var i = 0; i < removeCount && i < sortedEntries.length; i++) {
      _cachedUrls.remove(sortedEntries[i].key);
      if (kDebugMode) {

      }
    }
  }

  /// حفظ الفيديوهات الحالية والقادمة (ذكي)
  /// مثالي للـ pagination - حفظ الفيديوهات الحالية + الـ N فيديو القادم
  Future<void> smartPrecacheVideos(
    List<String> allUrls, {
    int? lookAheadCount, // عدد الفيديوهات القادمة للحفظ (from AppSettings if not provided)
    int currentIndex = 0,
    int? cacheValidDays,
  }) async {
    // ✅ Use AppSettings value if not provided
    final actualLookAhead = lookAheadCount ?? AppSettings.preCacheCount;
    final cacheDays = cacheValidDays ?? AppSettings.videoCacheDuration;
    
    final start = currentIndex;
    final end = (currentIndex + actualLookAhead).clamp(0, allUrls.length);

    final urlsToCache = allUrls.sublist(start, end);
    await precacheVideos(urlsToCache, cacheValidDays: cacheDays);
  }

  /// مسح الكاش
  void clearCache() {
    _cachedUrls.clear();
    _cachingUrls.clear();
  }

  /// مسح الكاش بشكل متزامن مع الـ API
  Future<void> clearAllCache() async {
    try {
      await CachedVideoPlayerPlus.clearAllCache();
      clearCache();
      if (kDebugMode) {

      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }

  /// الحصول على عدد الفيديوهات المخزنة
  int get cachedCount => _cachedUrls.length;

  /// الحصول على إحصائيات الكاش
  Map<String, dynamic> getCacheStats() {
    return {
      'cached': _cachedUrls.length,
      'caching': _cachingUrls.length,
      'total': _cachedUrls.length + _cachingUrls.length,
    };
  }
}
