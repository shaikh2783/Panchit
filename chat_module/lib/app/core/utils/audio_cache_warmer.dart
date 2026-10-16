import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AudioCacheWarmer {
  AudioCacheWarmer._();

  static final CacheManager _cacheManager = CacheManager(
    Config(
      'ukrainaAudioCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 80,
    ),
  );

  static final Set<String> _warmedUrls = <String>{};
  static final Map<String, Future<void>> _warmingTasks = <String, Future<void>>{};

  static Future<void> warm(String url) async {
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

  static Future<void> warmMany(Iterable<String> urls, {int limit = 4}) async {
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
      unawaited(warm(url));
    }
  }

  static Future<File?> getCachedFile(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) {
      return null;
    }

    await warm(normalized);
    try {
      return await _cacheManager.getSingleFile(normalized);
    } catch (_) {
      return null;
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
