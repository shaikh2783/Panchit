import 'package:snginepro/core/network/api_client.dart';
import 'package:snginepro/main.dart' show configCfgP;
import 'package:snginepro/features/auth/data/models/auth_response.dart';
class AuthApiService {
  AuthApiService(this._client);
  final ApiClient _client;
  Future<AuthResponse> signIn({
    required String identity,
    required String password,
    required String deviceType,
  }) async {
    final response = await _client.post(
      configCfgP('auth_signin'),
      body: {
        'username_email': identity,
        'password': password,
        'device_type': deviceType,
      },
    );
    return AuthResponse.fromJson(response);
  }
  Future<AuthResponse> signUp({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    String? gender,
    DateTime? birthdate,
    required String deviceType,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
      'device_type': deviceType,
    };
    // Add optional fields if provided
    if (gender != null && gender.isNotEmpty) {
      body['gender'] = gender; // Send gender_id (e.g., "1", "2", "3")
    }
    if (birthdate != null) {
      body['birthdate'] = '${birthdate.year}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}';
    }
    final response = await _client.post(
      configCfgP('auth_signup'),
      body: body,
    );
    return AuthResponse.fromJson(response);
  }
}
