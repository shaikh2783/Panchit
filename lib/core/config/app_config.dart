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
    // إذا كان المسار يحتوي على domain كامل، ارجعه كما هو
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return Uri.parse(relativePath);
    }
    // إذا كان المسار يحتوي على baseUrl بالفعل، لكن بدون protocol
    if (relativePath.contains(
      baseUrl.replaceFirst('https://', '').replaceFirst('http://', ''),
    )) {
      // أعد بناء URL مع protocol
      if (!relativePath.startsWith('http')) {
        return Uri.parse('https://$relativePath');
      }
      return Uri.parse(relativePath);
    }
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedMedia = mediaBasePath.startsWith('/')
        ? mediaBasePath.substring(1)
        : mediaBasePath;
    final normalizedRelative = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
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
