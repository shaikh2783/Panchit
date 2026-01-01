import 'package:flutter/foundation.dart';
import 'package:snginepro/main.dart';

@immutable
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.apiSecret,
    this.apiBasePath = '/apis/php',
    this.mediaBasePath = '/content/uploads',
  });

  final String baseUrl;
  final String apiKey;
  final String apiSecret;
  final String apiBasePath;
  final String mediaBasePath;

  /// Builds a fully qualified [Uri] targeting the PHP API.
  Uri endpoint(String relativePath) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedApiBase = apiBasePath.startsWith('/')
        ? apiBasePath.substring(1)
        : apiBasePath;
    final normalizedRelative = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    final combined = '$normalizedBase/$normalizedApiBase/$normalizedRelative';
    return Uri.parse(combined);
  }

  /// Resolves a relative media asset path (e.g., photos/..., videos/...) into a full [Uri].
  Uri mediaAsset(String relativePath) {
    // Normalize common double-prefix issues: domain/content/uploads/domain/content/uploads/...
    var cleaned = relativePath.trim();
    final baseWithoutProto =
        baseUrl.replaceFirst('https://', '').replaceFirst('http://', '');

    // Fix missing colon cases like https//domain → https://domain
    cleaned = cleaned.replaceAll('https//', 'https://').replaceAll('http//', 'http://');

    // CRITICAL FIX: If we find content/uploads followed by a full URL, keep only the last complete URL
    final mediaSegment = mediaBasePath.startsWith('/')
        ? mediaBasePath.substring(1)
        : mediaBasePath;
    
    // Find pattern like: .../content/uploads/https://domain/content/uploads/...
    // Keep only everything from the LAST occurrence of https:// or http://
    final lastHttpsIdx = cleaned.lastIndexOf('https://');
    final lastHttpIdx = cleaned.lastIndexOf('http://');
    final lastSchemeIdx = lastHttpsIdx > lastHttpIdx ? lastHttpsIdx : lastHttpIdx;
    
    if (lastSchemeIdx > 0) {
      // Check if there's content/uploads before this scheme
      final beforeScheme = cleaned.substring(0, lastSchemeIdx);
      if (beforeScheme.contains(mediaSegment)) {
        // Keep only from the last scheme onwards
        cleaned = cleaned.substring(lastSchemeIdx);
      }
    }

    // إذا كان المسار يحتوي على domain كامل، ارجعه كما هو
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return Uri.parse(cleaned);
    }

    // إذا كان المسار يحتوي على baseUrl بالفعل، لكن بدون protocol
    if (cleaned.contains(baseWithoutProto)) {
      // أعد بناء URL مع protocol
      if (!cleaned.startsWith('http')) {
        return Uri.parse('https://${cleaned.startsWith('//') ? cleaned.substring(2) : cleaned}');
      }
      return Uri.parse(cleaned);
    }

    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedMedia = mediaBasePath.startsWith('/')
        ? mediaBasePath.substring(1)
        : mediaBasePath;
    final normalizedRelative = cleaned.startsWith('/')
        ? cleaned.substring(1)
        : cleaned;
    final buffer = StringBuffer(normalizedBase);
    if (normalizedMedia.isNotEmpty) {
      buffer.write('/$normalizedMedia');
    }
    if (normalizedRelative.isNotEmpty) {
      buffer.write('/$normalizedRelative');
    }
    return Uri.parse(buffer.toString());
  }
}

/// Update these placeholders with the actual values from your Panchit installation.
AppConfig appConfig = _initializeAppConfig();

AppConfig _initializeAppConfig() {
  // محاولة الحصول على البيانات من cfgP

  return AppConfig(
    baseUrl: cfgP.first['w1'],
    apiKey: cfgP.first['1'],
    apiSecret: cfgP.first['2'],
  );

  // قيم افتراضية إذا لم تتوفر البيانات المشفرة
}
