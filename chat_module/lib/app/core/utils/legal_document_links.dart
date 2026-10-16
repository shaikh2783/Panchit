import '../../../api_config.dart';

class LegalDocumentLinks {
  LegalDocumentLinks._();

  static Uri get privacyPolicy => _resolve('/static/privacy');
  static Uri get termsOfUse => _resolve('/static/terms');

  static Uri _resolve(String path) {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    return baseUri.replace(path: path, queryParameters: null, fragment: null);
  }
}
