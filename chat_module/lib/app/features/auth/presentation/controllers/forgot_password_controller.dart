import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../data/api/api_exception.dart';
import '../../data/services/auth_service.dart';

enum ForgotPasswordStage { requestCode, verifyCode, resetPassword }

class ForgotPasswordController extends GetxController {
  ForgotPasswordController(this._authService);

  final AuthService _authService;

  final requestFormKey = GlobalKey<FormState>();
  final verifyFormKey = GlobalKey<FormState>();
  final resetFormKey = GlobalKey<FormState>();

  final identifierController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final stage = ForgotPasswordStage.requestCode.obs;
  final isSubmitting = false.obs;
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  @override
  void onClose() {
    identifierController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  String get currentIdentifier => identifierController.text.trim();

  void togglePasswordVisibility() {
    isPasswordHidden.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.toggle();
  }

  String? validateIdentifier(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppTranslations.forgotPasswordIdentifierRequired.tr;
    }
    return null;
  }

  String? validateCode(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppTranslations.forgotPasswordCodeRequired.tr;
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return AppTranslations.forgotPasswordNewPasswordRequired.tr;
    }
    if (normalized.length < 6) {
      return AppTranslations.signUpPasswordTooShort.tr;
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppTranslations.forgotPasswordConfirmPasswordRequired.tr;
    }
    if (value != passwordController.text) {
      return AppTranslations.signUpPasswordsDoNotMatch.tr;
    }
    return null;
  }

  Future<void> submitRequestCode() async {
    if (!(requestFormKey.currentState?.validate() ?? false)) {
      return;
    }

    await _runSubmission(() async {
      final message = await _authService.requestPasswordReset(
        identifier: identifierController.text,
      );
      stage.value = ForgotPasswordStage.verifyCode;
      Get.snackbar(
        AppTranslations.forgotPasswordCodeSent.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    });
  }

  Future<void> submitVerifyCode() async {
    if (!(verifyFormKey.currentState?.validate() ?? false)) {
      return;
    }

    await _runSubmission(() async {
      final message = await _authService.confirmPasswordResetCode(
        identifier: identifierController.text,
        code: codeController.text,
      );
      stage.value = ForgotPasswordStage.resetPassword;
      Get.snackbar(
        AppTranslations.forgotPasswordCodeVerified.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    });
  }

  Future<void> submitResetPassword() async {
    if (!(resetFormKey.currentState?.validate() ?? false)) {
      return;
    }

    await _runSubmission(() async {
      final message = await _authService.resetPassword(
        identifier: identifierController.text,
        code: codeController.text,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );
      Get.snackbar(
        AppTranslations.forgotPasswordPasswordUpdated.tr,
        message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      final sessionController = Get.find<SessionController>();
      sessionController.state.value = SessionViewState.login;
      Get.key.currentState?.popUntil((route) => route.isFirst);
    });
  }

  Future<void> _runSubmission(Future<void> Function() action) async {
    FocusManager.instance.primaryFocus?.unfocus();
    isSubmitting.value = true;
    try {
      await action();
    } on ApiException catch (error) {
      Get.snackbar(
        AppTranslations.forgotPassword.tr,
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.forgotPassword.tr,
        AppTranslations.loginFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
