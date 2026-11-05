import 'core/license/runtime/credential/api_credential_entry.dart';
import 'core/license/runtime/origin/api_origin_entry.dart';
import 'core/license/runtime/signature/api_signature_entry.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl => ApiOriginEntry.read();
  static String get apiKey => ApiCredentialEntry.read();
  static String get secretKey => ApiSignatureEntry.read();
}
