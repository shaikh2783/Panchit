import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

class VideoCacheWarmer {
  VideoCacheWarmer._();

  static final CacheManager _cacheManager = CacheManager(
    Config(
      'ukrainaVideoCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 40,
    ),
  );
  static final Set<String> _warmedUrls = <String>{};
  static final Map<String, Future<void>> _warmingTasks = <String, Future<void>>{};

  static Future<void> warm(
    String url, {
    Duration invalidateAfter = const Duration(days: 7),
  }) async {
    final normalized = url.trim();
    if (normalized.isEmpty || _warmedUrls.contains(normalized)) {
      return;
    }

    final existingTask = _warmingTasks[normalized];
    if (existingTask != null) {
      await existingTask;
      return;
    }

    final task = _warmInternal(normalized);
    _warmingTasks[normalized] = task;
    await task;
  }

  static Future<VideoPlayerController> createController(
    String url, {
    Duration invalidateAfter = const Duration(days: 7),
  }) async {
    final normalized = url.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(url, 'url', 'Video URL cannot be empty');
    }

    await warm(normalized, invalidateAfter: invalidateAfter);

    try {
      final cachedFile = await _cacheManager.getSingleFile(normalized);
      return VideoPlayerController.file(cachedFile);
    } catch (_) {
      return VideoPlayerController.networkUrl(Uri.parse(normalized));
    }
  }

  static Future<File?> getCachedFile(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final cached = await _cacheManager.getFileFromCache(normalized);
    return cached?.file;
  }

  static Future<VideoPlayerController> createImmediateController(
    String url,
  ) async {
    final normalized = url.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(url, 'url', 'Video URL cannot be empty');
    }

    final cachedFile = await getCachedFile(normalized);
    if (cachedFile != null) {
      return VideoPlayerController.file(cachedFile);
    }

    return VideoPlayerController.networkUrl(Uri.parse(normalized));
  }

  static Future<void> warmMany(
    Iterable<String> urls, {
    int limit = 3,
    Duration invalidateAfter = const Duration(days: 7),
  }) async {
    final uniqueUrls = <String>[];
    for (final url in urls) {
      final normalized = url.trim();
      if (normalized.isEmpty || uniqueUrls.contains(normalized)) {
        continue;
      }
      uniqueUrls.add(normalized);
      if (uniqueUrls.length >= limit) {
        break;
      }
    }

    for (final url in uniqueUrls) {
      unawaited(warm(url, invalidateAfter: invalidateAfter));
    }
  }

  static Future<void> _warmInternal(String normalizedUrl) async {
    try {
      await _cacheManager.getSingleFile(normalizedUrl);
      _warmedUrls.add(normalizedUrl);
    } catch (_) {
      // Ignore warming failures; the normal player path can still load later.
    } finally {
      _warmingTasks.remove(normalizedUrl);
    }
  }
}
