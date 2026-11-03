Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

/// Response for `GET /data/kyc/status`.
class KycStatusResponse {
  const KycStatusResponse({
    required this.success,
    required this.kycCompleted,
    this.message,
  });

  final bool success;
  final bool kycCompleted;
  final String? message;

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']);
    return KycStatusResponse(
      success: _bool(json['success']) || json['status'] == 'success',
      kycCompleted: _bool(
        data['kyc_completed'] ??
            data['kyc_verified'] ??
            json['kyc_completed'] ??
            json['kyc_verified'] ??
            json['is_kyc'],
      ),
      message: _string(json['message']),
    );
  }
}

/// Response for `POST /data/kyc/aadhaar/session`.
class KycSessionResponse {
  const KycSessionResponse({
    required this.success,
    required this.kycCompleted,
    this.sessionId,
    this.sdkApiKey,
    this.message,
  });

  final bool success;

  /// True when the user was already verified — per the backend contract,
  /// this response then has the same shape as `/data/kyc/status` and omits
  /// [sessionId]/[sdkApiKey] entirely. Callers must not open the DigiLocker
  /// SDK in that case.
  final bool kycCompleted;

  final String? sessionId;

  /// Sandbox API key used by the DigiLocker SDK.
  /// Returned by our backend together with the newly created DigiLocker
  /// session. Server-side Sandbox credentials/access tokens remain on the
  /// backend.
  final String? sdkApiKey;
  final String? message;

  factory KycSessionResponse.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']);
    return KycSessionResponse(
      // Tolerates both our own backend's response envelope and Sandbox's
      // native session-creation response shape (e.g. `{"code": 200, "data":
      // {"status": "created"}}`), in case either is ever proxied through
      // as-is.
      success:
          _bool(json['success']) ||
          json['status'] == 'success' ||
          json['code'] == 200 ||
          data['status'] == 'created',
      kycCompleted: _bool(
        data['kyc_completed'] ?? data['kyc_verified'] ?? json['kyc_completed'],
      ),
      sessionId: _string(
        data['session_id'] ??
            data['sessionId'] ??
            data['id'] ??
            json['session_id'],
      ),
      sdkApiKey: _string(
        data['sdk_api_key'] ?? data['sdkApiKey'] ?? json['sdk_api_key'],
      ),
      message: _string(json['message']),
    );
  }
}

/// Response for `POST /data/kyc/aadhaar/verify`.
class KycVerifyResponse {
  const KycVerifyResponse({
    required this.success,
    required this.kycCompleted,
    this.message,
    this.aadhaarName,
  });

  final bool success;
  final bool kycCompleted;
  final String? message;

  /// The e-KYC name DigiLocker returned for the verified Aadhaar, if the
  /// backend includes one. `null` when the backend omits it, in which case
  /// callers must not treat that as a mismatch.
  final String? aadhaarName;

  factory KycVerifyResponse.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']);
    return KycVerifyResponse(
      success: _bool(json['success']) || json['status'] == 'success',
      kycCompleted: _bool(
        data['kyc_completed'] ??
            data['kyc_verified'] ??
            json['kyc_completed'] ??
            json['kyc_verified'],
      ),
      message: _string(json['message']),
      aadhaarName: _string(
        data['kyc_name'] ??
            data['name'] ??
            data['aadhaar_name'] ??
            data['full_name'] ??
            json['kyc_name'] ??
            json['name'],
      ),
    );
  }
}
