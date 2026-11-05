import '../license_runtime.dart';

typedef ApiRuntimeNode = String Function();

class ApiRuntimeNodes {
  ApiRuntimeNodes._();

  static final List<ApiRuntimeNode> values = <ApiRuntimeNode>[
    () => LicenseRuntime.secretKey,
    () => _normalizeBaseUrl(LicenseRuntime.baseUrl),
    () => LicenseRuntime.apiKey,
  ];

  static String _normalizeBaseUrl(String rawUrl) {
    final normalized = rawUrl.trim();
    if (normalized.endsWith('/')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
