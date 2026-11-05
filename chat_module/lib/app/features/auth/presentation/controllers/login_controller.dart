import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/session_controller.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../data/api/api_exception.dart';
import '../../data/services/auth_service.dart';

class LoginController extends GetxController {
  LoginController(this._authService, this._sessionController);

  final AuthService _authService;
  final SessionController _sessionController;

  final formKey = GlobalKey<FormState>();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordHidden = true.obs;
  final rememberUser = true.obs;
  final isSubmitting = false.obs;

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.toggle();
  }

  void toggleRememberMe(bool? value) {
    rememberUser.value = value ?? false;
  }

  String? validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.identifierRequired.tr;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.passwordRequired.tr;
    }
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    isSubmitting.value = true;

    try {
      final result = await _authService.signIn(
        usernameEmail: identifierController.text,
        password: passwordController.text,
      );
      await _sessionController.applyLoginResult(result);
    } on ApiException catch (error) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      Get.snackbar(
        AppTranslations.loginFailed.tr,
        AppTranslations.loginFailed.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
