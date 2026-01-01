import 'package:snginepro/core/network/api_client.dart';
import 'package:flutter/foundation.dart';

/// Password Reset API Service
/// 
/// Handles all API calls for password reset functionality:
/// 1. Send reset code to email
/// 2. Verify reset code
/// 3. Reset password
class PasswordResetApiService {
  final ApiClient _apiClient;

  PasswordResetApiService(this._apiClient);

  /// Send password reset code to user's email
  /// 
  /// Parameters:
  /// - identity: Email or username
  /// 
  /// Response:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "message": "Verification code sent to your email"
  /// }
  /// ```
  Future<Map<String, dynamic>> sendResetCode(String identity) async {
    try {
      final response = await _apiClient.post(
        '/auth/forget_password',
        body: {'email': identity},
      );
      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to send reset code: $e',
      };
    }
  }

  /// Verify the reset code sent to email
  /// 
  /// Parameters:
  /// - email: User's email address
  /// - code: 6-digit code received via email
  /// 
  /// Response:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "message": "Code verified successfully",
  ///   "reset_key": "code123"
  /// }
  /// ```
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await _apiClient.post(
        '/auth/forget_password_confirm',
        body: {
          'email': email,
          'reset_key': code,
        },
      );
      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to verify code: $e',
      };
    }
  }

  /// Resend reset code to email
  /// 
  /// Parameters:
  /// - email: User's email address
  /// 
  /// Call this when user requests to resend the code
  /// 
  /// Response:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "message": "Code resent to your email"
  /// }
  /// ```
  Future<Map<String, dynamic>> resendResetCode(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/forget_password',
        body: {'email': email},
      );
      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to resend code: $e',
      };
    }
  }

  /// Reset password with new password
  /// 
  /// Parameters:
  /// - email: User's email address
  /// - resetKey: Reset code from verification step
  /// - password: New password
  /// - confirmPassword: Password confirmation
  /// 
  /// Note: This should be called after verifying the reset code
  /// 
  /// Response:
  /// ```json
  /// {
  ///   "status": "success",
  ///   "message": "Password reset successfully"
  /// }
  /// ```
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetKey,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/forget_password_reset',
        body: {
          'email': email,
          'reset_key': resetKey,
          'password': password,
          'confirm': confirmPassword,
        },
      );
      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to reset password: $e',
      };
    }
  }

  /// Complete password reset flow
  /// 
  /// This is a convenience method that combines all steps:
  /// 1. Send code
  /// 2. Verify code
  /// 3. Reset password
  /// 
  /// Parameters:
  /// - email: User's email address
  /// - resetKey: Reset code received via email
  /// - newPassword: New password
  /// - confirmPassword: Password confirmation
  Future<Map<String, dynamic>> completePasswordReset({
    required String email,
    required String resetKey,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/forget_password_reset',
        body: {
          'email': email,
          'reset_key': resetKey,
          'password': newPassword,
          'confirm': confirmPassword,
        },
      );
      return response;
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to complete password reset: $e',
      };
    }
  }
}