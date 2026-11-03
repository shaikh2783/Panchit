import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/features/kyc/data/models/kyc_models.dart';
import 'package:snginepro/main.dart' show configCfgP;

/// Handles Aadhaar/DigiLocker KYC verification calls.
///
/// The server is always treated as the source of truth for KYC status —
/// callers must not assume a user is verified based on local/cached state.
class KycApiService {
  KycApiService(this._client);

  final ApiClient _client;

  Future<KycStatusResponse> getKycStatus() async {
    final response = await _client.get(
      _endpoint('kyc_status', '/data/kyc/status'),
    );
    return KycStatusResponse.fromJson(response);
  }

  Future<KycSessionResponse> createAadhaarSession() async {
    final response = await _client.post(
      _endpoint('kyc_aadhaar_session', '/data/kyc/aadhaar/session'),
      body: const {},
    );
    return KycSessionResponse.fromJson(response);
  }

  Future<KycVerifyResponse> verifyAadhaarSession(String sessionId) async {
    final response = await _client.post(
      _endpoint('kyc_aadhaar_verify', '/data/kyc/aadhaar/verify'),
      body: {'session_id': sessionId},
    );
    return KycVerifyResponse.fromJson(response);
  }

  String _endpoint(String configKey, String fallback) {
    final configured = configCfgP(configKey);
    if (configured.trim().isNotEmpty) {
      return configured;
    }
    return fallback;
  }
}
