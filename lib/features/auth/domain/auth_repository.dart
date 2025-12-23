import 'package:snginepro/features/auth/data/datasources/auth_api_service.dart';
import 'package:snginepro/features/auth/data/models/auth_response.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final AuthApiService _apiService;

  Future<AuthResponse> signIn({
    required String identity,
    required String password,
    required String deviceType,
  }) {
    return _apiService.signIn(
      identity: identity,
      password: password,
      deviceType: deviceType,
    );
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
  }) {
    return _apiService.signUp(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
      gender: gender,
      birthdate: birthdate,
      deviceType: deviceType,
    );
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
  }) {
    return _apiService.signInWithGoogle(
      googleId: googleId,
      email: email,
      firstName: firstName,
      lastName: lastName,
      picture: picture,
      username: username,
      idToken: idToken,
      deviceType: deviceType,
    );
  }
}
