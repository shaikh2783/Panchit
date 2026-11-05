import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/api/api_endpoints.dart';
import '../../../../../settings.dart';
import '../models/auth_flow_state_model.dart';
import '../models/login_result_model.dart';

class AuthService {
  AuthService(this._apiClient, this._preferences);

  final ChatModuleApiClient _apiClient;
  final ChatAppPreferences _preferences;

  Map<String, dynamic> _buildDevicePayload() {
    final deviceType = Platform.isAndroid
        ? 'A'
        : Platform.isIOS
        ? 'I'
        : 'W';

    return <String, dynamic>{
      'device_type': deviceType,
      'device_os_version': Platform.operatingSystemVersion,
      'device_name': 'Messenger App',
    };
  }

  Future<LoginResultModel> signIn({
    required String usernameEmail,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.signIn,
      body: <String, dynamic>{
        'username_email': usernameEmail.trim(),
        'password': password,
        ..._buildDevicePayload(),
      },
    );

    final result = LoginResultModel.fromJson(response);
    await _storeLoginResult(result);
    return result;
  }

  Future<LoginResultModel> signUp({
    required String username,
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    String? gender,
  }) async {
    final normalizedGender = _normalizeSignupGender(gender);
    final body = <String, dynamic>{
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'first_name': firstname.trim(),
      'last_name': lastname.trim(),
      ..._buildDevicePayload(),
    };
    if (normalizedGender != null) {
      body['gender'] = normalizedGender;
    }

    if (verboseApiLoggingEnabled) {
      debugPrint(
        'AUTH SIGNUP PAYLOAD: ${const JsonEncoder.withIndent('  ').convert(body)}',
      );
    }

    final response = await _apiClient.post(ApiEndpoints.signUp, body: body);

    final result = LoginResultModel.fromJson(response);
    await _storeLoginResult(result);
    return result;
  }

  Future<AuthFlowStateModel> fetchAuthState() async {
    final response = await _apiClient.get(
      ApiEndpoints.authState,
      authenticated: true,
    );

    return AuthFlowStateModel.fromJson(
      response,
      fallbackNextStep: _preferences.getPendingNextStep(),
      fallbackEmail: _preferences.getPendingEmail(),
    );
  }

  Future<LoginResultModel> verifyTwoFactorCode({
    required int userId,
    required String code,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.authTwoFactorVerify,
      body: <String, dynamic>{
        'user_id': userId,
        'two_factor_key': code.trim(),
        ..._buildDevicePayload(),
      },
    );

    final result = LoginResultModel.fromJson(response);
    await _storeLoginResult(result);
    return result;
  }

  Future<AuthFlowStateModel> resendEmailActivationCode({
    String? authToken,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.authActivationEmailResend,
      authenticated: true,
      authTokenOverride: authToken,
    );

    return AuthFlowStateModel.fromJson(
      response,
      fallbackNextStep: 'activation',
      fallbackEmail: _preferences.getPendingEmail(),
    );
  }

  Future<AuthFlowStateModel> verifyEmailActivationCode({
    required String code,
    String? authToken,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.authActivationVerify,
      authenticated: true,
      authTokenOverride: authToken,
      body: <String, dynamic>{'code': code.trim()},
    );

    return AuthFlowStateModel.fromJson(
      response,
      fallbackEmail: _preferences.getPendingEmail(),
    );
  }

  Future<String> requestPasswordReset({required String identifier}) async {
    final normalizedIdentifier = identifier.trim();
    final response = await _apiClient.post(
      ApiEndpoints.authForgotPassword,
      body: <String, dynamic>{
        'email': normalizedIdentifier,
        'username_email': normalizedIdentifier,
        'identifier': normalizedIdentifier,
      },
    );

    return _resolveMessage(
      response,
      fallback: 'Password reset request sent successfully',
    );
  }

  Future<String> confirmPasswordResetCode({
    required String identifier,
    required String code,
  }) async {
    final normalizedIdentifier = identifier.trim();
    final normalizedCode = code.trim();
    final response = await _apiClient.post(
      ApiEndpoints.authForgotPasswordConfirm,
      body: <String, dynamic>{
        'email': normalizedIdentifier,
        'username_email': normalizedIdentifier,
        'identifier': normalizedIdentifier,
        'code': normalizedCode,
        'reset_code': normalizedCode,
      },
    );

    return _resolveMessage(
      response,
      fallback: 'Reset code verified successfully',
    );
  }

  Future<String> resetPassword({
    required String identifier,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedIdentifier = identifier.trim();
    final normalizedCode = code.trim();
    final response = await _apiClient.post(
      ApiEndpoints.authForgotPasswordReset,
      body: <String, dynamic>{
        'email': normalizedIdentifier,
        'username_email': normalizedIdentifier,
        'identifier': normalizedIdentifier,
        'code': normalizedCode,
        'reset_code': normalizedCode,
        'password': password,
        'confirm_password': confirmPassword,
        'confirm': confirmPassword,
      },
    );

    return _resolveMessage(
      response,
      fallback: 'Your password has been changed you can login now',
    );
  }

  Future<String> deleteAccount() async {
    final response = await _apiClient.post(
      ApiEndpoints.userDeleteAccount,
      authenticated: true,
    );

    await _preferences.clearSession();
    return _resolveMessage(
      response,
      fallback: 'Your account has been deleted successfully',
    );
  }

  Future<void> signOut() async {
    final shouldSignOutRemotely = !_preferences.isActiveTimelineBridgeSession();

    if (shouldSignOutRemotely) {
      try {
        await _apiClient.post(ApiEndpoints.signOut, authenticated: true);
      } catch (_) {
        // Clear local session even if the remote signout request fails.
      }
    }

    await _preferences.clearSession();
  }

  Future<void> _storeLoginResult(LoginResultModel result) async {
    if (_shouldTreatAsHome(result.resolvedNextStep)) {
      await _preferences.setAuthToken(result.sessionToken);
      await _preferences.setUserId(result.userId);
      await _preferences.setActiveTimelineBridgeSession(false);
      await _preferences.clearPendingSession();
      return;
    }

    await _preferences.clearSession();
    if (result.hasActiveSession) {
      await _preferences.setPendingSession(
        token: result.sessionToken,
        userId: result.userId,
        nextStep: result.resolvedNextStep,
        email: result.user?.email,
      );
    }
  }

  bool _shouldTreatAsHome(String nextStep) {
    final normalized = nextStep.trim().toLowerCase();
    if (normalized == 'home') {
      return true;
    }
    return !gettingStartedFlowEnabled && normalized == 'getting_started';
  }

  String? _normalizeSignupGender(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'male':
      case '1':
        return '1';
      case 'female':
      case '2':
        return '2';
      default:
        return null;
    }
  }

  String _resolveMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = response['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
  }
}
