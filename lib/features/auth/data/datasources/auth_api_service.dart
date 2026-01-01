import 'package:flutter/foundation.dart';
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
      body['birthdate'] =
          '${birthdate.year}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}';
    }

    final response = await _client.post(configCfgP('auth_signup'), body: body);
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> signInWithGoogle({
    required String googleId,
    required String email,
    String? firstName,
    String? lastName,
    String? picture,
    String? username,
    String? idToken,
    String deviceType = 'A',
  }) async {
    final body = <String, dynamic>{
      'google_id': googleId,
      'email': email,
      'device_type': deviceType,
    };

    if (firstName != null && firstName.isNotEmpty)
      body['first_name'] = firstName;
    if (lastName != null && lastName.isNotEmpty) body['last_name'] = lastName;
    if (picture != null && picture.isNotEmpty) body['picture'] = picture;
    if (username != null && username.isNotEmpty) body['username'] = username;
    if (idToken != null && idToken.isNotEmpty) {
      body['id_token'] = idToken;

    } else {

    }

    final response = await _client.post('/data/auth/google', body: body);
    return AuthResponse.fromJson(response);
  }
}
